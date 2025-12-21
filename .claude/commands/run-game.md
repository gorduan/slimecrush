# /run-game

Startet das SlimeCrush Spiel über MCP.

## Verwendung

```
/run-game
```

## Was es tut

1. Stoppt eventuell laufende Instanz
2. Startet das Godot-Projekt
3. Zeigt Debug-Output

## Implementierung

```
mcp__godot-mcp__run_project projectPath="e:/Claude Projekte/SlimeCrush JS/godot_project"
```

Nach 2 Sekunden:
```
mcp__godot-mcp__get_debug_output
```

## Erwartete Ausgabe

- "Godot project started in debug mode"
- Vulkan initialization message
- Any warnings or errors from the game

## Fehlerbehandlung

Bei Fehlern:
1. Prüfe ob Godot installiert ist
2. Prüfe GODOT_PATH Umgebungsvariable
3. Prüfe godot-mcp Server Status
