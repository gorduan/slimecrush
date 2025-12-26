extends RefCounted
class_name SkillTreeData
## SkillTreeData - Node-based skill tree for Story Mode progression
## Inspired by incremental games like Melvor Idle, Idleon, and visual skill trees

# Node types for visual representation
enum NodeType {
	CORE,       # Central starting node
	COLOR,      # Color unlock nodes
	SCORING,    # Point multiplier nodes
	SPECIAL,    # Special slime chance/power
	COMBO,      # Combo and cascade bonuses
	ABILITY,    # Active ability unlocks
	MOVES       # Move-related bonuses
}

# Icon names for each node type (matches UI icons)
const NODE_ICONS: Dictionary = {
	NodeType.CORE: "core",
	NodeType.COLOR: "color",
	NodeType.SCORING: "scoring",
	NodeType.SPECIAL: "special",
	NodeType.COMBO: "combo",
	NodeType.ABILITY: "ability",
	NodeType.MOVES: "moves"
}

# Colors for node types
const NODE_COLORS: Dictionary = {
	NodeType.CORE: Color("#e879f9"),      # Pink/Magenta
	NodeType.COLOR: Color("#a78bfa"),     # Purple
	NodeType.SCORING: Color("#fbbf24"),   # Yellow/Gold
	NodeType.SPECIAL: Color("#f472b6"),   # Pink
	NodeType.COMBO: Color("#fb923c"),     # Orange
	NodeType.ABILITY: Color("#60a5fa"),   # Blue
	NodeType.MOVES: Color("#4ade80")      # Green
}

# ============ SKILL TREE NODES ============
# Each node has: id, type, name, description, cost, max_level, effect_per_level, position, connections
# Position is relative (will be scaled in UI), connections are node IDs this connects TO

const NODES: Dictionary = {
	# ============ CORE NODE (Center) ============
	"core": {
		"type": NodeType.CORE,
		"name": "Slime Essence",
		"description": "The heart of your power. All paths begin here.",
		"cost": 0,
		"max_level": 1,
		"effect": "Unlocks the skill tree",
		"position": Vector2(0, 0),
		"connections": ["green_unlock", "point_boost_1", "combo_base", "striped_chance_1", "starting_moves_1"],
		"unlocked_by_default": true
	},

	# ============ COLOR UNLOCK BRANCH (Top-Left) ============
	"green_unlock": {
		"type": NodeType.COLOR,
		"name": "Green Awakening",
		"description": "Green slimes are already awakened.",
		"cost": 0,
		"max_level": 1,
		"effect": "Green slimes active (default)",
		"position": Vector2(-2, -1),
		"connections": ["blue_unlock", "green_mastery"],
		"unlocked_by_default": true,
		"color": "green"
	},
	"green_mastery": {
		"type": NodeType.SCORING,
		"name": "Green Mastery",
		"description": "+15% points from green matches per level",
		"cost": 50,
		"max_level": 5,
		"effect_per_level": 0.15,
		"effect_type": "color_multiplier_green",
		"position": Vector2(-3, -0.5),
		"connections": []
	},
	"blue_unlock": {
		"type": NodeType.COLOR,
		"name": "Blue Awakening",
		"description": "Awaken blue slimes. They match with gray blue slimes and give 2x base points.",
		"cost": 150,
		"max_level": 1,
		"effect": "Unlock blue color",
		"position": Vector2(-3, -2),
		"connections": ["blue_mastery", "purple_unlock"],
		"color": "blue"
	},
	"blue_mastery": {
		"type": NodeType.SCORING,
		"name": "Blue Mastery",
		"description": "+15% points from blue matches per level",
		"cost": 75,
		"max_level": 5,
		"effect_per_level": 0.15,
		"effect_type": "color_multiplier_blue",
		"position": Vector2(-4, -1.5),
		"connections": []
	},
	"purple_unlock": {
		"type": NodeType.COLOR,
		"name": "Purple Awakening",
		"description": "Awaken purple slimes. 3x base points.",
		"cost": 300,
		"max_level": 1,
		"effect": "Unlock purple color",
		"position": Vector2(-4, -3),
		"connections": ["purple_mastery", "yellow_unlock"],
		"color": "purple"
	},
	"purple_mastery": {
		"type": NodeType.SCORING,
		"name": "Purple Mastery",
		"description": "+15% points from purple matches per level",
		"cost": 100,
		"max_level": 5,
		"effect_per_level": 0.15,
		"effect_type": "color_multiplier_purple",
		"position": Vector2(-5, -2.5),
		"connections": []
	},
	"yellow_unlock": {
		"type": NodeType.COLOR,
		"name": "Yellow Awakening",
		"description": "Awaken yellow slimes. 4x base points.",
		"cost": 500,
		"max_level": 1,
		"effect": "Unlock yellow color",
		"position": Vector2(-3, -4),
		"connections": ["yellow_mastery", "orange_unlock"],
		"color": "yellow"
	},
	"yellow_mastery": {
		"type": NodeType.SCORING,
		"name": "Yellow Mastery",
		"description": "+15% points from yellow matches per level",
		"cost": 125,
		"max_level": 5,
		"effect_per_level": 0.15,
		"effect_type": "color_multiplier_yellow",
		"position": Vector2(-4, -4.5),
		"connections": []
	},
	"orange_unlock": {
		"type": NodeType.COLOR,
		"name": "Orange Awakening",
		"description": "Awaken orange slimes. 5x base points.",
		"cost": 800,
		"max_level": 1,
		"effect": "Unlock orange color",
		"position": Vector2(-2, -5),
		"connections": ["orange_mastery", "red_unlock"],
		"color": "orange"
	},
	"orange_mastery": {
		"type": NodeType.SCORING,
		"name": "Orange Mastery",
		"description": "+15% points from orange matches per level",
		"cost": 150,
		"max_level": 5,
		"effect_per_level": 0.15,
		"effect_type": "color_multiplier_orange",
		"position": Vector2(-3, -5.5),
		"connections": []
	},
	"red_unlock": {
		"type": NodeType.COLOR,
		"name": "Red Awakening",
		"description": "Awaken red slimes. The most valuable at 6x base points!",
		"cost": 1200,
		"max_level": 1,
		"effect": "Unlock red color",
		"position": Vector2(-1, -6),
		"connections": ["red_mastery", "color_master"],
		"color": "red"
	},
	"red_mastery": {
		"type": NodeType.SCORING,
		"name": "Red Mastery",
		"description": "+15% points from red matches per level",
		"cost": 200,
		"max_level": 5,
		"effect_per_level": 0.15,
		"effect_type": "color_multiplier_red",
		"position": Vector2(-2, -6.5),
		"connections": []
	},
	"color_master": {
		"type": NodeType.SCORING,
		"name": "Color Master",
		"description": "+5% points from ALL colored matches per level",
		"cost": 500,
		"max_level": 3,
		"effect_per_level": 0.05,
		"effect_type": "all_color_multiplier",
		"position": Vector2(0, -7),
		"connections": []
	},

	# ============ SCORING BRANCH (Top-Right) ============
	"point_boost_1": {
		"type": NodeType.SCORING,
		"name": "Point Boost I",
		"description": "+5% base points from all matches per level",
		"cost": 40,
		"max_level": 5,
		"effect_per_level": 0.05,
		"effect_type": "base_points",
		"position": Vector2(2, -1),
		"connections": ["point_boost_2", "match4_bonus"]
	},
	"point_boost_2": {
		"type": NodeType.SCORING,
		"name": "Point Boost II",
		"description": "+8% base points from all matches per level",
		"cost": 100,
		"max_level": 5,
		"effect_per_level": 0.08,
		"effect_type": "base_points",
		"position": Vector2(3, -2),
		"connections": ["point_boost_3"]
	},
	"point_boost_3": {
		"type": NodeType.SCORING,
		"name": "Point Boost III",
		"description": "+12% base points from all matches per level",
		"cost": 250,
		"max_level": 3,
		"effect_per_level": 0.12,
		"effect_type": "base_points",
		"position": Vector2(4, -3),
		"connections": []
	},
	"match4_bonus": {
		"type": NodeType.SCORING,
		"name": "Match-4 Expert",
		"description": "+10% bonus points from 4-match combos per level",
		"cost": 60,
		"max_level": 5,
		"effect_per_level": 0.10,
		"effect_type": "match4_bonus",
		"position": Vector2(3, -0.5),
		"connections": ["match5_bonus"]
	},
	"match5_bonus": {
		"type": NodeType.SCORING,
		"name": "Match-5 Expert",
		"description": "+15% bonus points from 5+ match combos per level",
		"cost": 120,
		"max_level": 5,
		"effect_per_level": 0.15,
		"effect_type": "match5_bonus",
		"position": Vector2(4, 0),
		"connections": ["special_score_bonus"]
	},
	"special_score_bonus": {
		"type": NodeType.SCORING,
		"name": "Special Activator",
		"description": "+20% points when special slimes activate per level",
		"cost": 150,
		"max_level": 5,
		"effect_per_level": 0.20,
		"effect_type": "special_activation_bonus",
		"position": Vector2(5, 0.5),
		"connections": []
	},

	# ============ COMBO BRANCH (Right) ============
	"combo_base": {
		"type": NodeType.COMBO,
		"name": "Combo Starter",
		"description": "+0.1 combo multiplier base per level",
		"cost": 50,
		"max_level": 5,
		"effect_per_level": 0.1,
		"effect_type": "combo_multiplier",
		"position": Vector2(2, 1),
		"connections": ["combo_master", "cascade_boost"]
	},
	"combo_master": {
		"type": NodeType.COMBO,
		"name": "Combo Master",
		"description": "+0.15 combo multiplier base per level",
		"cost": 150,
		"max_level": 5,
		"effect_per_level": 0.15,
		"effect_type": "combo_multiplier",
		"position": Vector2(3, 2),
		"connections": ["combo_legend"]
	},
	"combo_legend": {
		"type": NodeType.COMBO,
		"name": "Combo Legend",
		"description": "+0.2 combo multiplier base per level",
		"cost": 400,
		"max_level": 3,
		"effect_per_level": 0.2,
		"effect_type": "combo_multiplier",
		"position": Vector2(4, 3),
		"connections": []
	},
	"cascade_boost": {
		"type": NodeType.COMBO,
		"name": "Cascade Boost",
		"description": "+8% points per cascade step per level",
		"cost": 80,
		"max_level": 5,
		"effect_per_level": 0.08,
		"effect_type": "cascade_bonus",
		"position": Vector2(3, 0.5),
		"connections": ["chain_reaction"]
	},
	"chain_reaction": {
		"type": NodeType.COMBO,
		"name": "Chain Reaction",
		"description": "+3% chance for cascades to trigger extra matches",
		"cost": 200,
		"max_level": 5,
		"effect_per_level": 0.03,
		"effect_type": "chain_reaction_chance",
		"position": Vector2(4, 1),
		"connections": []
	},

	# ============ SPECIAL SLIMES BRANCH (Bottom-Right) ============
	"striped_chance_1": {
		"type": NodeType.SPECIAL,
		"name": "Striped Luck I",
		"description": "+4% chance for Match-4 to create striped slime",
		"cost": 60,
		"max_level": 5,
		"effect_per_level": 0.04,
		"effect_type": "striped_chance",
		"position": Vector2(1, 2),
		"connections": ["striped_chance_2", "wrapped_chance_1", "striped_power"]
	},
	"striped_chance_2": {
		"type": NodeType.SPECIAL,
		"name": "Striped Luck II",
		"description": "+6% chance for Match-4 to create striped slime",
		"cost": 150,
		"max_level": 3,
		"effect_per_level": 0.06,
		"effect_type": "striped_chance",
		"position": Vector2(2, 3),
		"connections": []
	},
	"striped_power": {
		"type": NodeType.SPECIAL,
		"name": "Striped Power",
		"description": "Striped slimes clear +1 additional row/column",
		"cost": 300,
		"max_level": 2,
		"effect_per_level": 1,
		"effect_type": "striped_extra_clear",
		"position": Vector2(0, 3),
		"connections": []
	},
	"wrapped_chance_1": {
		"type": NodeType.SPECIAL,
		"name": "Wrapped Luck I",
		"description": "+4% chance for L/T shapes to create wrapped slime",
		"cost": 80,
		"max_level": 5,
		"effect_per_level": 0.04,
		"effect_type": "wrapped_chance",
		"position": Vector2(2, 4),
		"connections": ["wrapped_chance_2", "wrapped_power", "colorbomb_chance"]
	},
	"wrapped_chance_2": {
		"type": NodeType.SPECIAL,
		"name": "Wrapped Luck II",
		"description": "+6% chance for L/T shapes to create wrapped slime",
		"cost": 180,
		"max_level": 3,
		"effect_per_level": 0.06,
		"effect_type": "wrapped_chance",
		"position": Vector2(3, 5),
		"connections": []
	},
	"wrapped_power": {
		"type": NodeType.SPECIAL,
		"name": "Wrapped Power",
		"description": "Wrapped slimes have +1 explosion radius",
		"cost": 350,
		"max_level": 2,
		"effect_per_level": 1,
		"effect_type": "wrapped_extra_radius",
		"position": Vector2(1, 5),
		"connections": []
	},
	"colorbomb_chance": {
		"type": NodeType.SPECIAL,
		"name": "Color Bomb Luck",
		"description": "+3% chance for Match-5 to create color bomb",
		"cost": 200,
		"max_level": 5,
		"effect_per_level": 0.03,
		"effect_type": "colorbomb_chance",
		"position": Vector2(3, 6),
		"connections": ["colorbomb_power"]
	},
	"colorbomb_power": {
		"type": NodeType.SPECIAL,
		"name": "Color Bomb Power",
		"description": "Color bombs also create striped slimes from cleared pieces",
		"cost": 600,
		"max_level": 1,
		"effect_per_level": 1,
		"effect_type": "colorbomb_creates_striped",
		"position": Vector2(4, 7),
		"connections": []
	},

	# ============ MOVES BRANCH (Bottom-Left) ============
	"starting_moves_1": {
		"type": NodeType.MOVES,
		"name": "Extra Moves I",
		"description": "+1 starting move per level",
		"cost": 75,
		"max_level": 5,
		"effect_per_level": 1,
		"effect_type": "starting_moves",
		"position": Vector2(-1, 2),
		"connections": ["starting_moves_2", "move_saver"]
	},
	"starting_moves_2": {
		"type": NodeType.MOVES,
		"name": "Extra Moves II",
		"description": "+2 starting moves per level",
		"cost": 200,
		"max_level": 3,
		"effect_per_level": 2,
		"effect_type": "starting_moves",
		"position": Vector2(-2, 3),
		"connections": ["starting_moves_3"]
	},
	"starting_moves_3": {
		"type": NodeType.MOVES,
		"name": "Extra Moves III",
		"description": "+3 starting moves per level",
		"cost": 500,
		"max_level": 2,
		"effect_per_level": 3,
		"effect_type": "starting_moves",
		"position": Vector2(-3, 4),
		"connections": []
	},
	"move_saver": {
		"type": NodeType.MOVES,
		"name": "Move Saver",
		"description": "+5% chance to not consume a move on match",
		"cost": 150,
		"max_level": 5,
		"effect_per_level": 0.05,
		"effect_type": "move_save_chance",
		"position": Vector2(-2, 1.5),
		"connections": ["emergency_reserve"]
	},
	"emergency_reserve": {
		"type": NodeType.MOVES,
		"name": "Emergency Reserve",
		"description": "+1 emergency move when reaching 0 moves",
		"cost": 400,
		"max_level": 3,
		"effect_per_level": 1,
		"effect_type": "emergency_moves",
		"position": Vector2(-3, 2),
		"connections": []
	},

	# ============ ABILITY BRANCH (Bottom) ============
	"ability_shuffle": {
		"type": NodeType.ABILITY,
		"name": "Shuffle Plus",
		"description": "Unlock: Free shuffle ability (2 uses per game)",
		"cost": 100,
		"max_level": 1,
		"effect": "Unlock shuffle ability",
		"ability_id": "shuffle_plus",
		"position": Vector2(0, 4),
		"connections": ["ability_row_sweep", "ability_column_sweep", "shuffle_upgrade"]
	},
	"shuffle_upgrade": {
		"type": NodeType.ABILITY,
		"name": "Shuffle Mastery",
		"description": "+1 shuffle use per game per level",
		"cost": 150,
		"max_level": 2,
		"effect_per_level": 1,
		"effect_type": "shuffle_uses",
		"position": Vector2(0, 5),
		"connections": []
	},
	"ability_row_sweep": {
		"type": NodeType.ABILITY,
		"name": "Row Sweep",
		"description": "Unlock: Clear entire row ability (1 use per game)",
		"cost": 200,
		"max_level": 1,
		"effect": "Unlock row sweep",
		"ability_id": "row_sweep",
		"position": Vector2(-1, 5),
		"connections": ["sweep_upgrade"]
	},
	"ability_column_sweep": {
		"type": NodeType.ABILITY,
		"name": "Column Sweep",
		"description": "Unlock: Clear entire column ability (1 use per game)",
		"cost": 200,
		"max_level": 1,
		"effect": "Unlock column sweep",
		"ability_id": "column_sweep",
		"position": Vector2(1, 5),
		"connections": ["sweep_upgrade"]
	},
	"sweep_upgrade": {
		"type": NodeType.ABILITY,
		"name": "Sweep Mastery",
		"description": "+1 sweep use per game per level",
		"cost": 250,
		"max_level": 2,
		"effect_per_level": 1,
		"effect_type": "sweep_uses",
		"position": Vector2(0, 6),
		"connections": ["ability_color_burst"]
	},
	"ability_color_burst": {
		"type": NodeType.ABILITY,
		"name": "Color Burst",
		"description": "Unlock: Destroy all slimes of chosen color (1 use)",
		"cost": 400,
		"max_level": 1,
		"effect": "Unlock color burst",
		"ability_id": "color_burst",
		"position": Vector2(0, 7),
		"connections": ["ability_slime_swap"]
	},
	"ability_slime_swap": {
		"type": NodeType.ABILITY,
		"name": "Slime Swap",
		"description": "Unlock: Swap any two slimes (1 use per game)",
		"cost": 500,
		"max_level": 1,
		"effect": "Unlock slime swap",
		"ability_id": "slime_swap",
		"position": Vector2(0, 8),
		"connections": []
	}
}

# Total: 50 nodes

# ============ HELPER FUNCTIONS ============

static func get_node(node_id: String) -> Dictionary:
	if NODES.has(node_id):
		return NODES[node_id].duplicate(true)
	return {}


static func get_all_node_ids() -> Array:
	return NODES.keys()


static func get_node_cost(node_id: String, current_level: int) -> int:
	var node = get_node(node_id)
	if node.is_empty():
		return 0
	# Cost scales with level
	return int(node.cost * (current_level + 1))


static func get_node_connections(node_id: String) -> Array:
	var node = get_node(node_id)
	if node.is_empty():
		return []
	return node.get("connections", [])


static func get_nodes_connecting_to(node_id: String) -> Array:
	var result: Array = []
	for id in NODES.keys():
		var connections = NODES[id].get("connections", [])
		if node_id in connections:
			result.append(id)
	return result


static func is_node_unlockable(node_id: String, unlocked_nodes: Dictionary) -> bool:
	# Core is always unlockable
	var node = get_node(node_id)
	if node.get("unlocked_by_default", false):
		return true

	# Check if any connected parent is unlocked
	var parents = get_nodes_connecting_to(node_id)
	for parent_id in parents:
		if unlocked_nodes.get(parent_id, 0) > 0:
			return true
	return false


static func get_node_effect_description(node_id: String, level: int) -> String:
	var node = get_node(node_id)
	if node.is_empty():
		return ""

	if node.has("effect"):
		return node.effect

	var effect_per_level = node.get("effect_per_level", 0)
	var total_effect = effect_per_level * level

	var effect_type = node.get("effect_type", "")
	match effect_type:
		"base_points", "color_multiplier_green", "color_multiplier_blue", \
		"color_multiplier_purple", "color_multiplier_yellow", "color_multiplier_orange", \
		"color_multiplier_red", "all_color_multiplier", "match4_bonus", "match5_bonus", \
		"special_activation_bonus", "cascade_bonus", "chain_reaction_chance", \
		"striped_chance", "wrapped_chance", "colorbomb_chance", "move_save_chance":
			return "+%d%%" % int(total_effect * 100)
		"combo_multiplier":
			return "+%.1f multiplier" % total_effect
		"starting_moves", "emergency_moves", "striped_extra_clear", \
		"wrapped_extra_radius", "shuffle_uses", "sweep_uses":
			return "+%d" % int(total_effect)
		"colorbomb_creates_striped":
			return "Creates striped slimes"
		_:
			return ""


static func get_color_from_type(node_type: NodeType) -> Color:
	return NODE_COLORS.get(node_type, Color.WHITE)
