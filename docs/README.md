# SlimeCrush Documentation

> **Version:** 0.1.0 | **Last Updated:** 2025-12-21

## Documentation Structure

```
docs/
├── README.md           # This file - Documentation overview
├── guides/             # How-to guides
│   ├── DEVELOPMENT.md  # Development setup & workflow
│   ├── GAME_MECHANICS.md # Match-3 mechanics reference
│   └── MOBILE.md       # Mobile/Android specifics
└── concepts/           # Feature designs & architecture
    └── [feature-name]/ # One folder per major feature
```

## Quick Links

| Document | Purpose |
|----------|---------|
| [DEVELOPMENT.md](guides/DEVELOPMENT.md) | Setup, running, debugging |
| [GAME_MECHANICS.md](guides/GAME_MECHANICS.md) | Match-3 rules & specials |
| [MOBILE.md](guides/MOBILE.md) | Touch controls, Android export |

## Documentation Rules

### Creating New Docs

1. **Guides** (`guides/`) - How to do something
   - Step-by-step instructions
   - Code examples
   - Troubleshooting

2. **Concepts** (`concepts/`) - Planning & architecture
   - Feature designs before implementation
   - Architecture decisions
   - Research notes

### Naming Conventions

- Use UPPERCASE for main docs: `DEVELOPMENT.md`
- Use lowercase-with-dashes for folders: `feature-name/`
- Include date in concept folders: `feature-name-2025-01/`

### Archiving

Completed concepts should be moved to `concepts/completed/` after implementation.

---

## Project Overview

**SlimeCrush** is a Match-3 puzzle game built with Godot 4.5 for Android.

### Features

- 8x8 game board with 6 slime colors
- Match-3 mechanics with cascades
- Special slimes (Striped, Wrapped, Color Bomb)
- World map with level progression
- Touch/swipe controls

### Tech Stack

- **Engine:** Godot 4.5
- **Language:** GDScript
- **Platform:** Android (Mobile-First)
- **Assets:** Pixel art sprites with shader effects

---

**Maintained by:** Claude Code
