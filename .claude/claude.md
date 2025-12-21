# SlimeCrush - Claude Code Project Context

> **Version:** 0.1.0 | **Engine:** Godot 4.5 | **Language:** GDScript | **Platform:** Android (Mobile-First)

## Quick Reference

```bash
# Run Project (via MCP)
mcp__godot-mcp__run_project projectPath="e:/Claude Projekte/SlimeCrush JS/godot_project"

# Stop Project
mcp__godot-mcp__stop_project

# Get Debug Output
mcp__godot-mcp__get_debug_output

# Git
git add . && git commit -m "feat: description" && git push
```

## Project Overview

**Purpose:** Match-3 Puzzle Game (Candy Crush Clone) for Android
**Architecture:** Scene-based with Autoload Singletons
**Repository:** https://github.com/gorduan/slimecrush

## Critical Rules

1. **SIGNALS** for communication - NEVER use direct node references across scenes
2. **ASYNC** with `await` - NEVER block with loops for animations
3. **TYPE HINTS** everywhere - Enables autocompletion and catches errors
4. **MODULATE** for visual effects - NEVER change sprite colors directly
5. **is_processing** flag - Prevent input during animations
6. **Mobile-First** - Test touch controls, consider performance

## Subagents (Use Proactively!)

> **Full Registry:** [AGENT_REGISTRY.md](./agents/AGENT_REGISTRY.md)

| Subagent | Use For |
|----------|---------|
| `godot-expert` | Scene structure, nodes, Godot patterns |
| `gdscript-expert` | GDScript syntax, signals, coroutines |
| `match3-expert` | Game mechanics, combos, specials |
| `mobile-expert` | Touch/swipe, Android export |
| `shader-expert` | Visual effects, materials |
| `code-explorer` | Debugging, "where is X?", error logs |
| `git-expert` | GitHub issues, milestones, releases |

**Rules:**
- **New features:** Create GitHub issue first, then implement
- **Bugs:** Use `code-explorer` to analyze, track in issue
- **UI/Visual:** Consider `shader-expert` for effects
- **Commits:** Follow conventional commit format

## Project Structure

```
SlimeCrush JS/
├── .claude/                    # Claude Documentation
│   ├── CLAUDE.md              # This file
│   ├── agents/                # Subagent definitions
│   ├── commands/              # Custom slash commands
│   ├── workflows/             # GitHub workflow guides
│   └── context/               # GDScript patterns, etc.
├── godot_project/             # Godot 4.5 Project
│   ├── autoload/              # Singleton Managers
│   │   ├── game_manager.gd    # Game state, score, levels
│   │   ├── save_manager.gd    # Persistence (ConfigFile)
│   │   └── audio_manager.gd   # SFX & Vibration
│   ├── scenes/
│   │   ├── main.tscn          # Main scene with UI
│   │   ├── game_board.tscn    # 8x8 game board
│   │   ├── slime.tscn         # Individual slime piece
│   │   └── world_map.tscn     # Level selection
│   ├── scripts/               # GDScript files
│   ├── shaders/               # Visual effects
│   ├── assets/                # Sprites, sounds
│   └── resources/             # TileSet, templates
├── docs/                      # Project documentation
└── Prototype/                 # Original HTML/JS version
```

## Game Mechanics Reference

### Slime Colors
| Color | Hex | Enum |
|-------|-----|------|
| Red | `#ff6b6b` | RED |
| Orange | `#ffa502` | ORANGE |
| Yellow | `#feca57` | YELLOW |
| Green | `#26de81` | GREEN |
| Blue | `#45aaf2` | BLUE |
| Purple | `#a55eea` | PURPLE |

### Special Slimes
| Type | Creation | Effect |
|------|----------|--------|
| Striped (H) | 4 horizontal | Clears row |
| Striped (V) | 4 vertical | Clears column |
| Wrapped | L/T-shape (5+) | 3x3 explosion |
| Color Bomb | 5 in a row | All of one color |

### Combinations
| Combo | Effect |
|-------|--------|
| Striped + Striped | Cross (row + column) |
| Wrapped + Wrapped | 5x5 explosion |
| Striped + Wrapped | 3 rows + 3 columns |
| Color Bomb + Color | All of that color |
| Color Bomb + Special | Converts all |
| Color Bomb + Color Bomb | Entire board |

## Known Issues & Solutions

### Input Blocking
**Problem:** All slimes stop responding to input
**Solution:** Safety timeout (3s) resets `is_processing` flag
**File:** `game_board.gd:_check_and_fix_board()`

### Shader UV Issues
**Problem:** Atlas textures break UV-based shaders
**Solution:** Use simple color tinting, avoid position-based effects
**File:** `slime_gel.gdshader`

## GDScript Style Guide

```gdscript
# Class declaration
class_name MyClass
extends Node2D

# Signals at top
signal something_happened(value: int)

# Constants
const MAX_VALUE: int = 100

# Exports
@export var speed: float = 100.0

# Public variables
var is_active: bool = false

# Private variables (underscore prefix)
var _internal_state: int = 0

# @onready for node references
@onready var sprite: Sprite2D = $Sprite2D

# Lifecycle methods first
func _ready() -> void:
    pass

func _process(delta: float) -> void:
    pass

# Public methods
func do_something() -> void:
    pass

# Private methods
func _helper_function() -> int:
    return 0
```

## Pre-Task Checklist

```
[ ] Read relevant docs
[ ] Check current game state
[ ] Identify affected files
[ ] Consider mobile implications
```

## Post-Task Checklist

```
[ ] Test in running game
[ ] Check debug output for errors
[ ] Update TODO if needed
[ ] Git commit with proper format
[ ] Update/close GitHub issue if applicable
```

## GitHub Workflow

> **Full Guide:** [GITHUB_WORKFLOW.md](./workflows/GITHUB_WORKFLOW.md)

### Issue-First Development

1. **New Feature?** → Create issue first: `gh issue create --title "feat: ..."`
2. **Found Bug?** → Document in issue with steps to reproduce
3. **Working on Issue?** → Add progress comments
4. **Finished?** → Reference issue in commit: `Closes #42`

### Commit Format

```bash
type: short description

- Detail 1
- Detail 2

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

Types: `feat`, `fix`, `refactor`, `docs`, `style`, `perf`, `chore`

### Milestones

| Milestone | Focus |
|-----------|-------|
| v0.1.0 | Core Match-3 ✅ |
| v0.2.0 | Special Slimes |
| v0.3.0 | Levels & Progression |
| v1.0.0 | Release Ready |

## Environment

| Tool | Path/Value |
|------|------------|
| Godot 4.5 | `E:\SteamLibrary\steamapps\common\Godot Engine\` |
| godot-mcp | `e:/Claude Projekte/godot-mcp/` |
| Project | `e:/Claude Projekte/SlimeCrush JS/godot_project` |

## Resources

- [Godot Docs](https://docs.godotengine.org/en/stable/)
- [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [Best Practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html)
- [Android Export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)

---

**Last Updated:** 2025-12-21
**Maintained by:** Claude Code
