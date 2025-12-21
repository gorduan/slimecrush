# Development Guide - SlimeCrush

> **Version:** 1.0.0 | **Last Updated:** 2025-12-21

## Setup

### Requirements

- Godot 4.5 (Steam version or standalone)
- Git
- (Optional) VSCode with godot-tools extension

### Environment

| Tool | Path |
|------|------|
| Godot 4.5 | `E:\SteamLibrary\steamapps\common\Godot Engine\` |
| Project | `e:\Claude Projekte\SlimeCrush JS\godot_project` |
| Repository | https://github.com/gorduan/slimecrush |

---

## Running the Game

### Via MCP (Claude Code)

```
mcp__godot-mcp__run_project projectPath="e:/Claude Projekte/SlimeCrush JS/godot_project"
```

### Via Godot Editor

1. Open Godot
2. Import project from `godot_project/project.godot`
3. Press F5 or click Play

### Check Debug Output

```
mcp__godot-mcp__get_debug_output
```

---

## Project Structure

```
godot_project/
├── autoload/              # Singletons (auto-loaded)
│   ├── game_manager.gd    # Score, levels, game state
│   ├── save_manager.gd    # Persistence
│   └── audio_manager.gd   # Sound effects
├── scenes/
│   ├── main.tscn          # Game UI
│   ├── game_board.tscn    # 8x8 board
│   ├── slime.tscn         # Single slime piece
│   └── world_map.tscn     # Level selection
├── scripts/               # Attached scripts
├── shaders/               # Visual effects
├── assets/
│   ├── slimes/            # Slime spritesheets
│   ├── tiles/             # Background tilesets
│   └── probs/             # Decorative elements
└── resources/             # TileSet, templates
```

---

## Key Files

### game_board.gd

Main game logic:
- Match detection
- Cascade system
- Special activations
- Input handling

### slime.gd

Individual slime piece:
- Touch/swipe detection
- Animations (swap, fall, match)
- Visual state (color, selection)

### game_manager.gd (Autoload)

Global state:
- Score tracking
- Level progression
- Win/lose conditions

---

## Debugging

### Common Issues

| Issue | Solution |
|-------|----------|
| Game freezes | Check `is_processing` flag, timeout should reset after 3s |
| Slimes don't respond | Check `is_input_enabled` flag |
| Visual glitches | Check shader parameters |
| Board has gaps | `_check_and_fix_board()` auto-repairs |

### Debug Output

Look for these in debug output:
- `MONITOR: null at X, Y` - Empty cell detected
- `Processing stuck for Xs` - Timeout triggered
- `Fixed N empty cells` - Auto-repair completed

---

## Git Workflow

### Commit Format

```
type: short description

- Detail 1
- Detail 2

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

### Types

- `feat:` New feature
- `fix:` Bug fix
- `refactor:` Code restructuring
- `docs:` Documentation
- `style:` Visual changes

---

## Testing Checklist

Before committing:

- [ ] Game starts without errors
- [ ] Match-3 detection works
- [ ] Cascades complete properly
- [ ] Special slimes activate correctly
- [ ] Touch controls responsive
- [ ] No debug warnings (except "Integer division")

---

**Maintained by:** Claude Code
