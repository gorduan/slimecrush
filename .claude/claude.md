# SlimeCrush - Claude Projekt-Dokumentation

## Projekt-Übersicht

**Name:** SlimeCrush
**Typ:** Match-3 Puzzle Game (Candy Crush Clone)
**Engine:** Godot 4.5
**Plattform:** Android (Mobile-First)
**Sprache:** GDScript

---

## Projektstruktur

```
SlimeCrush JS/
├── .claude/                    # Claude Dokumentation
│   ├── claude.md              # Diese Datei
│   └── logs/                  # Session-Logs
├── godot_project/             # Godot 4.5 Projekt
│   ├── autoload/              # Singleton Manager
│   │   ├── game_manager.gd    # Spielzustand, Score, Level
│   │   ├── save_manager.gd    # Highscore & Settings (ConfigFile)
│   │   └── audio_manager.gd   # Sound-Effekte & Vibration
│   ├── scenes/
│   │   ├── main.tscn          # Hauptszene mit UI
│   │   ├── game_board.tscn    # 8x8 Spielfeld
│   │   └── slime.tscn         # Einzelner Slime mit Partikeln
│   ├── scripts/
│   │   ├── main.gd            # UI-Controller
│   │   ├── game_board.gd      # Match-3 Logik
│   │   └── slime.gd           # Touch/Swipe & Animationen
│   ├── project.godot          # Projekt-Konfiguration
│   └── export_presets.cfg     # Android Export Settings
└── Prototype/                 # Original HTML/JS Version
    ├── index.html
    └── game.js
```

---

## Implementierte Features

### Spielmechanik
- [x] 8x8 Spielfeld
- [x] Match-3 Logik
- [x] Touch/Swipe-Steuerung
- [x] Kaskaden-System (Gravity)
- [x] Combo-Multiplikator

### Slime-Farben (Candy Crush Palette)
| Farbe | Hex-Code | Enum |
|-------|----------|------|
| Rot | `#ff6b6b` | RED |
| Orange | `#ffa502` | ORANGE |
| Gelb | `#feca57` | YELLOW |
| Grün | `#26de81` | GREEN |
| Blau | `#45aaf2` | BLUE |
| Lila | `#a55eea` | PURPLE |

### Special Slimes
| Typ | Erstellung | Effekt |
|-----|------------|--------|
| Striped (H) | 4 horizontal | Löscht Zeile |
| Striped (V) | 4 vertikal | Löscht Spalte |
| Wrapped | L/T-Form (5+) | 3x3 Explosion |
| Color Bomb | 5 in Reihe | Alle einer Farbe |

### Kombinationen
| Kombination | Effekt |
|-------------|--------|
| Striped + Striped | Kreuz (Zeile + Spalte) |
| Wrapped + Wrapped | 4x4 Explosion |
| Striped + Wrapped | 3 Zeilen + 3 Spalten |
| Color Bomb + Farbe | Alle dieser Farbe |
| Color Bomb + Special | Wandelt alle um |
| Color Bomb + Color Bomb | Gesamtes Spielfeld |

---

## Bekannte Probleme & Fixes

### Problem 1: Schwarzer Bildschirm beim Start
**Ursache:** Fehlende `default_font.tres` Referenz
**Fix:** In `project.godot` die Zeile `theme/custom_font=...` entfernt

### Problem 2: "Integer division" Warnung
**Ursache:** GDScript Warnung (nicht kritisch)
**Status:** Ignoriert (hat keinen Einfluss)

### Problem 3: "unused parameter" Warnung
**Ursache:** `music_name` Parameter nicht verwendet
**Fix:** Zu `_music_name` umbenannt

---

## Entwicklungsumgebung

### Godot Installation
- **Pfad:** `E:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`
- **Version:** 4.5 stable

### MCP Integration
- **godot-mcp** installiert unter: `e:/Claude Projekte/godot-mcp/`
- **Konfiguriert mit:** `GODOT_PATH` Umgebungsvariable

### VSCode Setup (Optional)
- Extension: `geequlim.godot-tools`
- LSP Port: 6005

---

## Nächste Schritte

### Hohe Priorität
- [ ] Spiel starten und testen
- [ ] Fehler im Debugger analysieren
- [ ] Touch-Steuerung auf Mobilgerät testen

### Mittlere Priorität
- [ ] Echte Sound-Dateien hinzufügen
- [ ] Partikel-Effekte verbessern
- [ ] Level-System erweitern

### Niedrige Priorität
- [ ] Hintergrundmusik
- [ ] Achievements
- [ ] Leaderboard

---

## Wichtige Befehle

### Godot über MCP starten
```
(Nach Claude Code Neustart verfügbar)
```

### Projekt manuell öffnen
```bash
"E:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --path "e:/Claude Projekte/SlimeCrush JS/godot_project"
```

### APK exportieren
1. In Godot: Project → Export
2. Android Preset auswählen
3. Export Project klicken

---

## Ressourcen & Links

- [Godot Docs](https://docs.godotengine.org/en/stable/)
- [GDScript Referenz](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)
- [Android Export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)
- [godot-mcp GitHub](https://github.com/Coding-Solo/godot-mcp)

---

*Zuletzt aktualisiert: 2024-12-20*
