# Game Mechanics Guide - SlimeCrush

> **Version:** 1.0.0 | **Last Updated:** 2025-12-21

## Overview

SlimeCrush is a Match-3 puzzle game inspired by Candy Crush. Players swap adjacent slimes to create matches of 3 or more of the same color.

---

## Board

- **Size:** 8x8 grid
- **Cell Size:** 64 pixels
- **Colors:** 6 different slime colors

### Coordinate System

```
(0,0) -----> X (7,0)
  |
  |
  v
  Y
(0,7)        (7,7)
```

---

## Basic Mechanics

### Matching

- **Minimum:** 3 slimes in a row (horizontal or vertical)
- **Detection:** After every swap, check entire board
- **Priority:** Larger matches first, then position-based

### Cascades

1. Matches are removed
2. Slimes above fall down (gravity)
3. New slimes spawn at top
4. Check for new matches
5. Repeat until no matches

### Scoring

| Match | Points |
|-------|--------|
| 3 slimes | 60 |
| 4 slimes | 120 |
| 5 slimes | 200 |
| Combo multiplier | x1.5 per cascade |

---

## Slime Colors

| Color | Enum | Tint Value |
|-------|------|------------|
| Red | `RED` | `Color(1.8, 0.4, 0.4)` |
| Orange | `ORANGE` | `Color(1.8, 1.0, 0.3)` |
| Yellow | `YELLOW` | `Color(1.8, 1.8, 0.4)` |
| Green | `GREEN` | `Color(0.4, 1.5, 0.5)` |
| Blue | `BLUE` | `Color(1.0, 1.0, 1.0)` |
| Purple | `PURPLE` | `Color(1.4, 0.5, 1.5)` |

---

## Special Slimes

### Striped Slime (Horizontal)

**Creation:** Match 4 slimes horizontally
**Effect:** Clears entire row when matched
**Visual:** Horizontal stripe overlay

### Striped Slime (Vertical)

**Creation:** Match 4 slimes vertically
**Effect:** Clears entire column when matched
**Visual:** Vertical stripe overlay

### Wrapped Slime

**Creation:** Match 5+ slimes in L or T shape
**Effect:** 3x3 explosion around the slime
**Visual:** Circular border glow

### Color Bomb

**Creation:** Match 5 slimes in a straight line
**Effect:** Removes all slimes of matched color
**Visual:** Rainbow circular segments

---

## Special Combinations

When two special slimes are swapped together:

| Combination | Effect |
|-------------|--------|
| Striped + Striped | Cross pattern (row + column) |
| Wrapped + Wrapped | 5x5 explosion |
| Striped + Wrapped | 3 rows + 3 columns |
| Color Bomb + Regular | All of that color |
| Color Bomb + Striped | All of color become striped |
| Color Bomb + Wrapped | All of color become wrapped |
| Color Bomb + Color Bomb | Clears entire board |

---

## Level System

### Win Condition

- Reach target score before running out of moves

### Level Data

```gdscript
var level_data = {
    "target_score": 1000,
    "max_moves": 30,
    "board_template": "standard_8x8"
}
```

### Difficulty Progression

- Higher levels: Higher target scores
- Fewer moves available
- More complex board layouts

---

## Input Handling

### Touch/Swipe

1. Touch down on slime → Record start position
2. Drag → Calculate delta
3. Release or threshold reached → Determine direction
4. **Threshold:** 30 pixels minimum swipe

### Direction Detection

```gdscript
if abs(delta.x) > abs(delta.y):
    direction = Vector2i(1, 0) if delta.x > 0 else Vector2i(-1, 0)
else:
    direction = Vector2i(0, 1) if delta.y > 0 else Vector2i(0, -1)
```

---

## Animation Timings

| Animation | Duration |
|-----------|----------|
| Swap | 0.2s |
| Invalid swap (bounce back) | 0.15s x 2 |
| Fall | 0.3s |
| Match (destroy) | 0.3s |
| Spawn | 0.3s |
| Special creation | 0.15s x 2 |

---

## Processing States

The game board has several states:

1. **IDLE** - Waiting for input
2. **PROCESSING** - Checking matches, cascading
3. **ANIMATING** - Playing animations

Input is blocked during PROCESSING and ANIMATING states.

---

**Maintained by:** Claude Code
