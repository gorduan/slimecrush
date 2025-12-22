extends Node2D
class_name WorldMap
## WorldMap - Manages the procedurally generated tile-based world
## Uses 8 TileMapLayers for terrain, decorations and walls
## Generates 2 screens at a time, scrolls up between levels

# Layer references
@onready var dirt_base: TileMapLayer = $DirtBase
@onready var terrain_layer1: TileMapLayer = $TerrainLayer1
@onready var terrain_layer2: TileMapLayer = $TerrainLayer2
@onready var snow_layer: TileMapLayer = $SnowLayer
@onready var grass_layer: TileMapLayer = $GrassLayer
@onready var wall_layer1: TileMapLayer = $WallLayer1
@onready var wall_layer2: TileMapLayer = $WallLayer2
@onready var wall_layer3: TileMapLayer = $WallLayer3

# TileSet will be assigned in editor or loaded
var world_tileset: TileSet

# Tile size in pixels
const TILE_SIZE: int = 16

# Screen size in pixels (native viewport)
const SCREEN_WIDTH: int = 720
const SCREEN_HEIGHT: int = 1280

# Map dimensions in tiles
# 32 tiles wide (scaled 1.5x in scene, covers screen + overflow)
# With scale 1.5, each tile is 24px, screen 1280px tall = ~54 tiles visible
var map_width_tiles: int = 32  # 32 tiles wide
var tiles_per_screen: int = 54  # Tiles per screen at scale 1.5

# Current level offset (which screen we're on, 0 = first level)
var current_level_offset: int = 0

# Terrain source IDs (will be set after TileSet is configured)
enum TerrainType {
	DIRT,
	SAND,
	STONE,
	SNOW,
	GRASS,
	WALL
}

# Atlas source IDs in the TileSet (order must match TileSet setup)
var terrain_source_ids: Dictionary = {
	TerrainType.DIRT: 0,
	TerrainType.SAND: 1,
	TerrainType.STONE: 2,
	TerrainType.SNOW: 3,
	TerrainType.GRASS: 4,
	TerrainType.WALL: 5
}

# Noise generator for terrain
var noise: FastNoiseLite
var path_noise: FastNoiseLite  # Separate noise for smooth path wobble

# Path generation - center path with wobble
const PATH_CENTER: int = 16       # Center of the path (middle of 32 tiles)
const PATH_WIDTH: int = 10        # Width of main path (10 tiles - doubled)
const PATH_WOBBLE_MAX: int = 3    # Max wobble (-3 to +3 tiles)

# Debug grid overlay
var debug_grid_visible: bool = false


func _ready() -> void:
	_setup_noise()
	# TileSet must be assigned to layers in editor first
	# Then we can generate the world


func _setup_noise() -> void:
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.05
	noise.seed = randi()

	# Path noise - lower frequency for smooth, gentle curves
	path_noise = FastNoiseLite.new()
	path_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	path_noise.frequency = 0.08  # Smooth curves, not too jagged
	path_noise.seed = randi()


func set_tileset(tileset: TileSet) -> void:
	world_tileset = tileset
	# Apply tileset to all layers
	dirt_base.tile_set = tileset
	terrain_layer1.tile_set = tileset
	terrain_layer2.tile_set = tileset
	snow_layer.tile_set = tileset
	grass_layer.tile_set = tileset
	wall_layer1.tile_set = tileset
	wall_layer2.tile_set = tileset
	wall_layer3.tile_set = tileset


func generate_world(stage: int, level_in_stage: int) -> void:
	# Clear existing tiles
	clear_all_layers()
	current_level_offset = 0

	# Generate 2 screens worth of terrain (current + next level area)
	var biome = _get_biome_for_stage(stage)
	_generate_screen_area(0, biome)  # Current screen (y = 0 to tiles_per_screen)
	_generate_screen_area(-1, biome)  # Next screen above (y = -tiles_per_screen to 0)

	# Generate walls for first/last level of stage
	_generate_walls(stage, level_in_stage)


func generate_next_screen(stage: int) -> void:
	# Called when scrolling to next level - generate new screen above
	current_level_offset += 1
	var biome = _get_biome_for_stage(stage)

	# Generate new screen above current view
	var screen_y_offset = -(current_level_offset + 1)
	_generate_screen_area(screen_y_offset, biome)

	# Clear old screen below (2 screens back)
	if current_level_offset >= 2:
		var old_screen_y = (current_level_offset - 2) * tiles_per_screen
		_clear_screen_area(old_screen_y)


func _generate_screen_area(screen_offset: int, biome: Dictionary) -> void:
	# Generate terrain for one screen's worth of tiles
	# screen_offset: 0 = first screen, -1 = screen above, -2 = two screens above, etc.
	var y_start = screen_offset * tiles_per_screen
	var y_end = y_start + tiles_per_screen

	# Generate dirt base for this area
	var dirt_cells: Array[Vector2i] = []
	for x in range(map_width_tiles):
		for y in range(y_start, y_end):
			dirt_cells.append(Vector2i(x, y))
	if dirt_cells.size() > 0:
		dirt_base.set_cells_terrain_connect(dirt_cells, 0, TerrainType.DIRT)

	# Generate terrain layers for this area
	_generate_terrain_for_area(y_start, y_end, biome)


func _clear_screen_area(y_start: int) -> void:
	# Clear one screen's worth of tiles
	var y_end = y_start + tiles_per_screen
	for x in range(map_width_tiles):
		for y in range(y_start, y_end):
			var pos = Vector2i(x, y)
			dirt_base.erase_cell(pos)
			terrain_layer1.erase_cell(pos)
			terrain_layer2.erase_cell(pos)
			snow_layer.erase_cell(pos)
			grass_layer.erase_cell(pos)
			wall_layer1.erase_cell(pos)
			wall_layer2.erase_cell(pos)
			wall_layer3.erase_cell(pos)


func _generate_terrain_for_area(y_start: int, y_end: int, biome: Dictionary) -> void:
	# Center path with slight wobble (-1 to +1), terrain on sides
	var half_width: int = PATH_WIDTH / 2  # 2

	# Collect cells for terrain (only on sides, not in path)
	var primary_cells: Array[Vector2i] = []
	var accent_cells: Array[Vector2i] = []

	for x in range(map_width_tiles):
		for y in range(y_start, y_end):
			var pos = Vector2i(x, y)

			# Get path offset for this row using smooth noise (-1, 0, or +1)
			var path_offset: int = _get_path_offset(y)
			var current_center: int = PATH_CENTER + path_offset

			# Calculate path bounds for this row
			var path_left: int = current_center - half_width
			var path_right: int = current_center + half_width

			# Skip path tiles - let dirt base show through
			if x >= path_left and x <= path_right:
				continue

			# All side tiles get primary terrain
			primary_cells.append(pos)

			# Add some accent variation using noise
			var noise_val = noise.get_noise_2d(x, y)
			if noise_val > 0.3:
				accent_cells.append(pos)

	# Apply terrain in batches
	if primary_cells.size() > 0:
		terrain_layer1.set_cells_terrain_connect(primary_cells, 0, biome["primary"])
	if accent_cells.size() > 0:
		terrain_layer2.set_cells_terrain_connect(accent_cells, 0, biome["accent"])


func clear_all_layers() -> void:
	dirt_base.clear()
	terrain_layer1.clear()
	terrain_layer2.clear()
	snow_layer.clear()
	grass_layer.clear()
	wall_layer1.clear()
	wall_layer2.clear()
	wall_layer3.clear()


func _get_biome_for_stage(stage: int) -> Dictionary:
	# Return biome configuration for this stage
	match stage:
		1, 2:
			return {
				"primary": TerrainType.GRASS,
				"secondary": TerrainType.DIRT,
				"accent": TerrainType.STONE
			}
		3, 4:
			return {
				"primary": TerrainType.SAND,
				"secondary": TerrainType.STONE,
				"accent": TerrainType.DIRT
			}
		5, 6:
			return {
				"primary": TerrainType.STONE,
				"secondary": TerrainType.DIRT,
				"accent": TerrainType.SAND
			}
		_:  # Stage 7+
			return {
				"primary": TerrainType.SNOW,
				"secondary": TerrainType.STONE,
				"accent": TerrainType.DIRT
			}


func _generate_walls(_stage: int, level_in_stage: int) -> void:
	# Level 1: Walls at bottom-left and bottom-right of first screen
	if level_in_stage == 1:
		_place_wall_corner(wall_layer1, 0, tiles_per_screen - 10, true, true)  # Bottom-left
		_place_wall_corner(wall_layer1, map_width_tiles - 10, tiles_per_screen - 10, false, true)  # Bottom-right

	# Level 10: Walls at top-left and top-right
	if level_in_stage == 10:
		var top_y = -tiles_per_screen
		_place_wall_corner(wall_layer1, 0, top_y, true, false)  # Top-left
		_place_wall_corner(wall_layer1, map_width_tiles - 10, top_y, false, false)  # Top-right


func _place_wall_corner(layer: TileMapLayer, start_x: int, start_y: int, _is_left: bool, _is_bottom: bool) -> void:
	# Place a 10x10 wall corner section using terrain autotiling
	var cells: Array[Vector2i] = []
	for x in range(10):
		for y in range(10):
			var tile_x = start_x + x
			var tile_y = start_y + y
			cells.append(Vector2i(tile_x, tile_y))
	layer.set_cells_terrain_connect(cells, 0, TerrainType.WALL)


# Utility function to convert world position to tile position
func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x) / TILE_SIZE, int(world_pos.y) / TILE_SIZE)


# Utility function to convert tile position to world position (center of tile)
func tile_to_world(tile_pos: Vector2i) -> Vector2:
	return Vector2(tile_pos.x * TILE_SIZE + TILE_SIZE / 2, tile_pos.y * TILE_SIZE + TILE_SIZE / 2)


# ============================================
# PATH HELPER - Smooth wobble for natural path
# ============================================

func _get_path_offset(y: int) -> int:
	# Use noise to get smooth path offset (-PATH_WOBBLE_MAX to +PATH_WOBBLE_MAX)
	# The noise provides smooth transitions so the path looks natural
	var noise_val: float = path_noise.get_noise_1d(float(y))

	# Map noise (-1 to 1) to offset (-3 to +3)
	var offset: int = roundi(noise_val * PATH_WOBBLE_MAX)
	return clampi(offset, -PATH_WOBBLE_MAX, PATH_WOBBLE_MAX)


func _is_path_tile(x: int, y: int) -> bool:
	# Check if position is in the path (accounting for wobble)
	var path_offset: int = _get_path_offset(y)
	var current_center: int = PATH_CENTER + path_offset
	var half_width: int = PATH_WIDTH / 2
	var path_left: int = current_center - half_width
	var path_right: int = current_center + half_width
	return x >= path_left and x <= path_right


# ============================================
# DEBUG GRID - Toggle visible grid overlay
# ============================================

func toggle_debug_grid(active: bool) -> void:
	debug_grid_visible = active
	queue_redraw()


func _draw() -> void:
	if not debug_grid_visible:
		return

	# Draw grid lines for visible area
	var grid_color = Color(1, 1, 1, 0.5)
	var path_color = Color(1, 0.84, 0.34, 0.5)  # Gold for path area
	var line_width = 1.0

	# Calculate visible y range (2 screens worth)
	var y_start = -tiles_per_screen
	var y_end = tiles_per_screen * 2

	# Draw vertical lines
	for x in range(map_width_tiles + 1):
		var x_pos = x * TILE_SIZE
		draw_line(Vector2(x_pos, y_start * TILE_SIZE), Vector2(x_pos, y_end * TILE_SIZE), grid_color, line_width)

	# Draw horizontal lines
	for y in range(y_start, y_end + 1):
		var y_pos = y * TILE_SIZE
		draw_line(Vector2(0, y_pos), Vector2(map_width_tiles * TILE_SIZE, y_pos), grid_color, line_width)

	# Highlight path area with colored overlay
	for y in range(y_start, y_end):
		var path_offset: int = _get_path_offset(y)
		var current_center: int = PATH_CENTER + path_offset
		var half_width: int = PATH_WIDTH / 2
		var path_left: int = current_center - half_width
		var path_right: int = current_center + half_width

		# Draw path highlight
		var rect = Rect2(
			path_left * TILE_SIZE,
			y * TILE_SIZE,
			(path_right - path_left + 1) * TILE_SIZE,
			TILE_SIZE
		)
		draw_rect(rect, path_color, false, 2.0)

	# Draw tile coordinates for reference (every 5 tiles)
	var font = ThemeDB.fallback_font
	var font_size = 10
	for x in range(0, map_width_tiles, 5):
		for y in range(y_start, y_end, 5):
			var pos = Vector2(x * TILE_SIZE + 2, y * TILE_SIZE + 12)
			draw_string(font, pos, "%d,%d" % [x, y], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
