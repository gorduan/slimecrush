# SlimeCrush - Godot 4 Mobile Game

Ein Candy Crush inspiriertes Match-3 Puzzle-Spiel, entwickelt mit Godot 4 für Android.

## Features

### Spielmechanik
- **8x8 Spielfeld** mit Touch/Swipe-Steuerung
- **Match-3 Logik** mit Kaskaden-System
- **Combo-System** mit Score-Multiplikatoren

### 6 Slime-Farben (Candy Crush Palette)
| Farbe | Hex-Code |
|-------|----------|
| Rot | `#ff6b6b` |
| Orange | `#ffa502` |
| Gelb | `#feca57` |
| Grün | `#26de81` |
| Blau | `#45aaf2` |
| Lila | `#a55eea` |

### Special Slimes (Power-Ups)
1. **Striped Slime** (4 in einer Reihe)
   - Horizontal: Löscht komplette Zeile
   - Vertikal: Löscht komplette Spalte

2. **Wrapped Slime** (L- oder T-Form mit 5+ Slimes)
   - Explodiert im 3x3 Bereich

3. **Color Bomb** (5 in einer Reihe)
   - Löscht alle Slimes einer Farbe

### Kombinationen
| Kombination | Effekt |
|-------------|--------|
| Striped + Striped | Kreuzexplosion |
| Wrapped + Wrapped | 4x4 Explosion |
| Striped + Wrapped | 3 Zeilen + 3 Spalten |
| Color Bomb + Farbe | Löscht alle dieser Farbe |
| Color Bomb + Special | Wandelt alle einer Farbe um |
| Color Bomb + Color Bomb | Löscht gesamtes Spielfeld |

### Zusätzliche Features
- Highscore-Speicherung
- Level-System mit steigender Schwierigkeit
- Partikel-Effekte für Explosionen
- Sound-Effekte
- Vibration bei Combos (Mobile)

## Projektstruktur

```
godot_project/
├── autoload/           # Singleton Manager
│   ├── game_manager.gd    # Spielzustand & Score
│   ├── save_manager.gd    # Persistente Daten
│   └── audio_manager.gd   # Sound & Musik
├── scenes/             # Godot Szenen
│   ├── main.tscn          # Hauptszene
│   ├── game_board.tscn    # Spielfeld
│   └── slime.tscn         # Einzelner Slime
├── scripts/            # GDScript Dateien
│   ├── main.gd            # UI Controller
│   ├── game_board.gd      # Spiellogik
│   └── slime.gd           # Slime Verhalten
├── project.godot       # Projekt-Konfiguration
└── export_presets.cfg  # Android Export Settings
```

## Installation & Setup

### Voraussetzungen
- Godot 4.2 oder neuer
- Android SDK (für Mobile Export)
- OpenJDK 17

### Projekt öffnen
1. Godot 4 starten
2. "Import" klicken
3. `project.godot` auswählen

### Android Export einrichten
1. Editor Settings → Export → Android
2. Android SDK Pfad setzen
3. Debug Keystore erstellen oder vorhandenen verwenden
4. Project → Install Android Build Template

### APK erstellen
1. Project → Export
2. "Android" Preset auswählen
3. "Export Project" klicken
4. APK-Dateiname wählen

## Steuerung

### Mobile (Touch)
- **Swipe**: Slimes tauschen
- **Tap**: Slime auswählen, dann benachbarten antippen

### Desktop (Maus)
- **Klick + Drag**: Slimes tauschen
- **Klick**: Auswählen und tauschen

## Technische Details

### Rendering
- Mobile Renderer für optimale Performance
- GPU Particles für Effekte
- Tween-Animationen für flüssige Bewegungen

### Speicherung
- ConfigFile für Einstellungen und Highscore
- `user://` Pfad für plattformübergreifende Kompatibilität

### Audio
- Prozedural generierte Sound-Effekte
- Separate Audio-Busse für Musik und SFX

## Lizenz

MIT License - Frei verwendbar für eigene Projekte.

## Credits

Inspiriert von:
- Candy Crush Saga (King)
- Godot Match-3 Tutorials und Community-Projekte
