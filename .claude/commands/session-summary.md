# Session Summary

Create a structured handoff summary of work done in this session.

## Purpose

Create a `handoff.md` file that enables:
- Another session to pick up exactly where you left off
- Clear understanding of what was done and why
- No context loss between sessions

## Required Sections

### 1. Work Completed
```markdown
## Completed This Session

- [x] **[Task/Feature Name]**
  - Files: `path/to/file.py`, `path/to/other.py`
  - Summary: [Brief description of what was implemented]
  - Tests: [Added/Updated/None needed]
```

### 2. In Progress (if any)
```markdown
## In Progress

- [ ] **[Task Name]** - [Current State]
  - What's done: [List completed parts]
  - What's remaining: [List remaining work]
  - Current blocker: [If any]
  - Files touched: [List files]
```

### 3. Blockers (if any)
```markdown
## Blockers

### [Blocker Title]
- **Issue**: [What's blocking progress]
- **Attempted**: [What was tried]
- **Needed**: [What would resolve this]
- **Impact**: [What can't proceed until resolved]
```

### 4. Key Decisions
```markdown
## Key Decisions Made

### [Decision Title]
- **Decision**: [What was decided]
- **Rationale**: [Why this choice]
- **Alternatives Considered**: [What else was evaluated]
- **Impact**: [What this affects going forward]
```

### 5. Files Changed Summary
```markdown
## Files Changed

| File | Change Type | Description |
|------|-------------|-------------|
| `src/api/users.py` | Modified | Added validation to create_user |
| `tests/test_users.py` | Added | Tests for user validation |
| `src/models/user.py` | Modified | Added email field |
```

### 6. Next Session Should
```markdown
## Next Session Priorities

1. **[Highest Priority]**: [Why this is first]
2. **[Second Priority]**: [Brief description]
3. **[Third Priority]**: [Brief description]

### Context for Next Session
- [Important context that might be forgotten]
- [Any gotchas or warnings]
- [References to relevant docs or code]
```

## Full Template

```markdown
# Session Handoff - {{DATE}}

## Session Goal
[What was the objective for this session?]

## Completed This Session

- [x] **[Task 1]**
  - Files: `file1.py`
  - Summary: [What was done]

- [x] **[Task 2]**
  - Files: `file2.py`, `file3.py`
  - Summary: [What was done]

## In Progress

- [ ] **[Task Name]** - [X% complete]
  - Done: [Completed parts]
  - Remaining: [What's left]
  - Files: `file.py`

## Blockers

[None / List any blockers with details]

## Key Decisions Made

### [Decision 1]
- **Decision**: [What]
- **Rationale**: [Why]

## Files Changed

| File | Change | Description |
|------|--------|-------------|
| `file.py` | Modified | [What changed] |

## Git Status
- Branch: `feature/xyz`
- Last commit: `abc123 - [commit message]`
- Uncommitted changes: [Yes/No - list if yes]

## Next Session Priorities

1. [First priority and why]
2. [Second priority]
3. [Third priority]

## Context Notes

- [Important context]
- [Gotchas or warnings]
```

## Instructions

1. Review all changes made in this session
2. Gather git status and recent commits
3. Document any incomplete work clearly
4. Note all decisions and their rationale
5. Create clear priorities for next session
6. Save as `handoff.md` in project root

## Output

Generate the handoff summary and save it to `./handoff.md`.
