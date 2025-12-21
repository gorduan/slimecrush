# /check-errors

Holt den aktuellen Debug-Output und analysiert Fehler.

## Verwendung

```
/check-errors
```

## Was es tut

1. Ruft `mcp__godot-mcp__get_debug_output` auf
2. Filtert nach Errors und Warnings
3. Gibt Zusammenfassung mit Lösungsvorschlägen

## Implementierung

```
mcp__godot-mcp__get_debug_output
```

## Typische Fehler

### "Processing stuck for Xs"
**Ursache:** Animation oder Match-Processing hängt
**Lösung:** Safety timeout greift automatisch, prüfe `is_processing` Flag

### "null at X, Y"
**Ursache:** Leere Zelle im Board
**Lösung:** `_check_and_fix_board()` wird automatisch aufgerufen

### "Integer division"
**Status:** Harmlose Warnung, kann ignoriert werden

### "unused parameter"
**Lösung:** Parameter mit `_` prefix umbenennen (z.B. `_unused`)
