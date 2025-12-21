# SlimeCrush - TileMap & Level-System Implementation Plan

## Übersicht
Umbau des Spiels von statischem 8x8 Board zu vollständigem Level-System mit:
- TileMapLayer-basiertem Hintergrund (8 Layer)
- Scrollender Kamera zwischen Levels
- Stage/Biom-System (10 Level pro Stage)
- Variable Board-Formen (vordefinierte Templates)
- Viewport: 720x1280 (Mobile Portrait)

---

## Vorhandene Assets

### Tileset PNGs (16x16 Pixel pro Tile)
- `assets/tiles/dirt/tileset_dirt.png`
- `assets/tiles/sand/tileset_sand.png`
- `assets/tiles/stone/tileset_stone.png`
- `assets/tiles/snow/tileset_snow.png`
- `assets/tiles/gras/tileset_gras.png`
- `assets/tiles/wall/tileset_wall.png`

### Godot 3 TileSet-Dateien (NICHT kompatibel mit Godot 4!)
Die `.tres` Dateien in den Unterordnern sind Godot 3 Format (`format=2`).
Die Bitmask-Daten sind aber korrekt und können als Referenz dienen.
**Lösung:** TileBitTools Plugin verwenden (bereits installiert in `addons/tile_bit_tools/`)

### Props (für später)
- `assets/probs/Rocks.png`
- `assets/probs/Vegetation.png`
- `assets/probs/Trees/` (verschiedene Modelle und Größen)

---

## Bereits erstellte Dateien

### 1. world_map.tscn
**Pfad:** `scenes/world_map.tscn`
- 8 TileMapLayer Nodes mit Z-Index -8 bis -1
- Referenziert `resources/world_tileset.tres`
- Script: `scripts/world_map.gd`

**Layer-Struktur:**
| Layer | Name | Z-Index | Inhalt |
|-------|------|---------|--------|
| 1 | DirtBase | -8 | Immer gefüllt mit Dirt |
| 2 | TerrainLayer1 | -7 | Sand/Stone/Dirt/Leer |
| 3 | TerrainLayer2 | -6 | Sand/Stone/Dirt/Leer |
| 4 | SnowLayer | -5 | Snow/Leer |
| 5 | GrassLayer | -4 | Gras/Leer |
| 6 | WallLayer1 | -3 | Wände |
| 7 | WallLayer2 | -2 | Wände |
| 8 | WallLayer3 | -1 | Wände |

### 2. world_map.gd
**Pfad:** `scripts/world_map.gd`
- FastNoiseLite für Terrain-Generation
- Biom-System nach Stage
- Funktionen: `generate_world()`, `clear_area()`, `_generate_terrain_layers()`

### 3. world_tileset.tres
**Pfad:** `resources/world_tileset.tres`
- Leeres TileSet mit 16x16 Tile-Größe
- **MUSS IM EDITOR KONFIGURIERT WERDEN**

---

## NÄCHSTER SCHRITT: TileSet im Editor konfigurieren

### Mit TileBitTools Plugin:

1. **TileSet öffnen:** `resources/world_tileset.tres`

2. **Atlas Sources hinzufügen (6 Stück):**
   - Klick auf **"+"** → **"Atlas"**
   - Texture laden: `assets/tiles/dirt/tileset_dirt.png`
   - Bei Frage "Create tiles automatically?" → **Ja**
   - Wiederholen für: sand, stone, snow, gras, wall

3. **Terrain Set erstellen:**
   - Im Inspector: **Terrain Sets** → **Add Element**
   - Mode: **"Match Corners and Sides"**
   - Terrain hinzufügen und benennen (z.B. "Dirt")

4. **TileBitTools Template anwenden:**
   - Atlas Source auswählen
   - Alle Tiles auswählen (Ctrl+A)
   - Im unteren Panel: TileBitTools
   - Template: **"3x3 Minimal"** oder **"Blob 47"**
   - **Apply** klicken
   - Für jede Source wiederholen

---

## Sprint-Plan

### Sprint 1: TileMap Grundlagen ✅ (teilweise)
- [x] TileSet Resource erstellen
- [x] 8 TileMapLayer Scene erstellen
- [x] TileBitTools Plugin installieren
- [ ] **TileSet im Editor konfigurieren** ← AKTUELL
- [ ] Manuell testen (Tiles malen)

### Sprint 2: Prozedurale Generation
- [ ] WorldGenerator testen
- [ ] Biom-System verfeinern
- [ ] world_map in main.tscn einbinden

### Sprint 3: Board-System
- [ ] Board Templates definieren (20 Stück)
  ```gdscript
  const TEMPLATE_L_SHAPE = [
      [1,1,1,0,0],
      [1,1,1,0,0],
      [1,1,1,1,1],
      [1,1,1,1,1],
      [1,1,1,1,1],
  ]
  ```
- [ ] GameBoard für variable Größe anpassen
- [ ] `is_valid_position()` Funktion
- [ ] Slimes verkleinern (Scale 1.8 → ~1.0 für 3x3 Tiles = 48px)

### Sprint 4: Kamera & Progression
- [ ] Viewport auf 720x1280 setzen
- [ ] Camera2D mit Scroll-Funktion
- [ ] Stage/Level System in GameManager
- [ ] Wand-Logik (Level 1: unten, Level 10: oben)

---

## Biom-System

| Stage | Biom | Primary | Secondary | Accent |
|-------|------|---------|-----------|--------|
| 1-2 | Wiese | Gras | Dirt | Stone |
| 3-4 | Wüste | Sand | Stone | Dirt |
| 5-6 | Gebirge | Stone | Dirt | Sand |
| 7+ | Schnee | Snow | Stone | Dirt |

---

## Level-System Details

- **10 Level pro Stage**
- **Kamera scrollt nach oben** nach jedem Level
- **Map-Größe:** 2x Bildschirmhöhe (720x2560 Pixel = 45x160 Tiles)
- **Nach Scroll:** Unterer Bereich löschen, oberen generieren
- **Wände:**
  - Level 1: Unten-links und unten-rechts
  - Level 10: Oben-links und oben-rechts

---

## Board Templates (zu erstellen)

Vordefinierte Formen als 2D-Arrays:
1. `TEMPLATE_SQUARE_5x5` - Klein
2. `TEMPLATE_SQUARE_6x6`
3. `TEMPLATE_SQUARE_7x7`
4. `TEMPLATE_SQUARE_8x8` - Standard
5. `TEMPLATE_SQUARE_9x9` - Groß
6. `TEMPLATE_L_SHAPE`
7. `TEMPLATE_L_SHAPE_MIRRORED`
8. `TEMPLATE_T_SHAPE`
9. `TEMPLATE_CROSS`
10. `TEMPLATE_DIAMOND`
11. `TEMPLATE_DONUT` (Loch in der Mitte)
12. `TEMPLATE_HOURGLASS`
13. `TEMPLATE_ARROW_UP`
14. `TEMPLATE_ARROW_DOWN`
15. `TEMPLATE_HEART`
16. `TEMPLATE_STAIRS`
17. `TEMPLATE_ZIGZAG`
18. `TEMPLATE_SPLIT` (2 getrennte Bereiche)
19. `TEMPLATE_CORNERS` (nur Ecken verbunden)
20. `TEMPLATE_FRAME` (Rahmen mit Loch)

---

## Wichtige Code-Änderungen

### game_manager.gd erweitern:
```gdscript
var current_stage: int = 1
var current_level_in_stage: int = 1
var levels_per_stage: int = 10
var board_template: Array = []
```

### game_board.gd anpassen:
```gdscript
func is_valid_position(pos: Vector2i) -> bool:
    if pos.x < 0 or pos.x >= board_width:
        return false
    if pos.y < 0 or pos.y >= board_height:
        return false
    return board_template[pos.y][pos.x] == 1

func _initialize_board_from_template(template: Array) -> void:
    # Nur auf gültigen Positionen Slimes spawnen
```

### slime.gd/slime.tscn:
- AnimatedSprite Scale: 1.8 → ~1.0
- CELL_SIZE anpassen

---

## Dateien die noch erstellt werden müssen

1. `resources/board_templates.gd` - Alle Board-Formen
2. `scripts/game_camera.gd` - Kamera-Scrolling
3. `autoload/world_generator.gd` - (optional, Logik aktuell in world_map.gd)

---

## Referenz-Links

- [TileBitTools Plugin](https://github.com/dandeliondino/tile_bit_tools)
- [Godot 4 TileMapLayer Docs](https://docs.godotengine.org/en/4.5/classes/class_tilemaplayer.html)
- [Candy Crush Board Designs](https://candycrush.fandom.com/wiki/Category:Levels_by_board_design)

---

*Zuletzt aktualisiert: 2024-12-20*
