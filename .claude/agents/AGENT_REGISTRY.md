# Agent Registry - SlimeCrush

> **Last Updated:** 2025-12-21
> **Total Agents:** 6

---

## Active Agents Overview

| Name | Domain | Use For |
|------|--------|---------|
| `godot-expert` | Engine/Scenes | Scene structure, nodes, Godot patterns |
| `gdscript-expert` | Scripting | GDScript syntax, signals, coroutines |
| `match3-expert` | Game Logic | Match detection, combos, specials |
| `mobile-expert` | Platform | Touch/swipe, Android export |
| `shader-expert` | Graphics | Visual effects, materials |
| `code-explorer` | Analysis | Debugging, error logs, "where is X?" |

---

## Agent Cards

### godot-expert

**File:** `godot-expert.md`
**Description:** Godot Engine specialist for scene architecture and node patterns

**Primary Use Cases:**
- Scene organization and hierarchy
- Node selection (when to use which node type)
- Autoload/Singleton patterns
- Resource management
- Export configuration

**When to Use:**
```
"How should I structure this feature as scenes?"
"Which node type is best for X?"
"How do I set up Android export?"
```

---

### gdscript-expert

**File:** `gdscript-expert.md`
**Description:** GDScript language specialist

**Primary Use Cases:**
- Signal implementation
- Coroutines with `await`
- Type hints and static typing
- Performance optimization
- Design patterns in GDScript

**When to Use:**
```
"How do I implement this pattern in GDScript?"
"Why isn't my signal working?"
"How to optimize this loop?"
```

---

### match3-expert

**File:** `match3-expert.md`
**Description:** Match-3 game mechanics specialist

**Primary Use Cases:**
- Match detection algorithms
- Cascade/gravity systems
- Special piece creation
- Combo detection
- Board validation

**When to Use:**
```
"How should I detect L-shaped matches?"
"Improve combo detection"
"Fix cascade animation timing"
```

---

### mobile-expert

**File:** `mobile-expert.md`
**Description:** Mobile platform specialist (Android focus)

**Primary Use Cases:**
- Touch/swipe input handling
- Screen resolution adaptation
- Performance on mobile
- Android export and signing
- Vibration feedback

**When to Use:**
```
"Touch detection isn't working"
"How to support different screen sizes?"
"Android export fails"
```

---

### shader-expert

**File:** `shader-expert.md`
**Description:** Visual effects and shader specialist

**Primary Use Cases:**
- Canvas item shaders
- Color effects (tinting, transparency)
- Particle systems
- Animation effects
- Performance-friendly visuals

**When to Use:**
```
"Create gel-ball transparency effect"
"Add glow to matched slimes"
"Optimize visual effects"
```

---

### code-explorer

**File:** `code-explorer.md`
**Description:** Codebase analysis and debugging specialist

**Primary Use Cases:**
- "Where is X implemented?"
- Error log analysis
- Bug investigation
- Code flow tracing
- Dependency analysis

**When to Use:**
```
"Why does the game freeze?"
"Where is scoring calculated?"
"Find all uses of signal X"
```

---

## Usage Guidelines

### When to Use Agents

**DO use agents for:**
- Complex multi-step implementations
- Debugging mysterious issues
- Learning best practices
- Code review and optimization

**DON'T use agents for:**
- Single-line fixes
- Simple questions
- Trivial tasks

### Agent Workflow

1. **Identify Domain** - Which area does the task belong to?
2. **Select Agent** - Pick the most relevant specialist
3. **Provide Context** - Give relevant file paths and error messages
4. **Review Output** - Agents provide recommendations, not final code

---

**Registry Version:** 1.0.0
**Maintained by:** Claude Code
