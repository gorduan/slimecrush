# GitHub Workflow - SlimeCrush

> **Version:** 1.0.0 | **Last Updated:** 2025-12-21

## Repository

- **URL:** https://github.com/gorduan/slimecrush
- **Default Branch:** main

---

## Issue Workflow

### Feature Request → Issue

Every new feature should be tracked as a GitHub issue BEFORE implementation:

```bash
# Create feature issue
gh issue create \
  --title "feat: [Feature Name]" \
  --body "## Description
[What the feature does]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Technical Notes
[Implementation hints]"
```

### Bug Report → Issue

```bash
gh issue create \
  --title "bug: [Bug Description]" \
  --body "## Bug Description
[What's happening]

## Steps to Reproduce
1. Step 1
2. Step 2

## Expected Behavior
[What should happen]

## Actual Behavior
[What happens instead]"
```

### Adding Progress Comments

When working on an issue, add comments for:
- Progress updates
- Related bug discoveries
- Technical decisions

```bash
# Add comment to issue
gh issue comment 42 --body "Found the cause: [explanation]"
```

### Closing with Commits

Reference issues in commits to auto-close:

```bash
git commit -m "feat: implement color bomb effect

Closes #42"
```

---

## Milestone Workflow

### Project Milestones

| Milestone | Focus | Target |
|-----------|-------|--------|
| v0.1.0 | Core Match-3 | ✅ Done |
| v0.2.0 | Special Slimes | In Progress |
| v0.3.0 | Levels & Progression | Planned |
| v0.4.0 | Polish & Effects | Planned |
| v1.0.0 | Release Ready | Planned |

### Creating Milestones

```bash
gh api repos/gorduan/slimecrush/milestones \
  --method POST \
  --field title="v0.2.0 - Special Slimes" \
  --field description="All special slime types and combinations" \
  --field due_on="2025-01-15T00:00:00Z"
```

### Assigning Issues to Milestones

```bash
gh issue edit 42 --milestone "v0.2.0 - Special Slimes"
```

### Checking Milestone Progress

```bash
# List issues in milestone
gh issue list --milestone "v0.2.0 - Special Slimes"

# View milestone stats
gh api repos/gorduan/slimecrush/milestones
```

---

## Branch Strategy

### Branch Naming

| Type | Format | Example |
|------|--------|---------|
| Feature | `feat/description` | `feat/color-bomb-combo` |
| Bug Fix | `fix/description` | `fix/cascade-overlap` |
| Refactor | `refactor/description` | `refactor/match-detection` |

### Feature Branch Workflow

```bash
# 1. Create branch from main
git checkout main
git pull
git checkout -b feat/new-feature

# 2. Work on feature (multiple commits OK)
git add .
git commit -m "feat: start implementation"
git commit -m "feat: add helper function"

# 3. Push and create PR
git push -u origin feat/new-feature
gh pr create --title "feat: New Feature" --body "Closes #42"

# 4. After merge, cleanup
git checkout main
git pull
git branch -d feat/new-feature
```

---

## Commit Convention

### Format

```
type: short description

- Optional detail 1
- Optional detail 2

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

### Types

| Type | When to Use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructuring (no behavior change) |
| `docs` | Documentation only |
| `style` | Visual/UI changes |
| `perf` | Performance improvements |
| `chore` | Maintenance, dependencies |

---

## Release Workflow

### Pre-Release Checklist

- [ ] All milestone issues closed
- [ ] Game tested on Android device
- [ ] No critical bugs open
- [ ] Version updated in project.godot

### Creating Release

```bash
# 1. Tag the release
git tag -a v0.2.0 -m "Special Slimes Update"
git push origin v0.2.0

# 2. Create GitHub release
gh release create v0.2.0 \
  --title "v0.2.0 - Special Slimes" \
  --notes "## What's New
- Striped slimes (H/V)
- Wrapped slimes
- Color Bomb
- All special combinations

## Bug Fixes
- Fixed cascade timing"

# 3. Optionally attach APK
gh release upload v0.2.0 ./exports/slimecrush-0.2.0.apk
```

---

## Quick Reference

| Task | Command |
|------|---------|
| List issues | `gh issue list` |
| View issue | `gh issue view 42` |
| Create issue | `gh issue create` |
| Close issue | `gh issue close 42` |
| Comment on issue | `gh issue comment 42 --body "text"` |
| List PRs | `gh pr list` |
| Create PR | `gh pr create` |
| Merge PR | `gh pr merge 42` |
| List milestones | `gh api repos/gorduan/slimecrush/milestones` |
| Create release | `gh release create v0.x.0` |

---

**Maintained by:** Claude Code
