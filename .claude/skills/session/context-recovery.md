---
name: context-recovery
description: This skill should be used when the user says "what were we doing", "where were we", "continue from last session", "pick up where we left off", "what's the status", "I'm back", "let's continue", or any indication of resuming previous work.
memory:
  scope: project
---

# Context Recovery

Helps recover context when resuming work after a break.

## Memory Integration

Always read `LEARNINGS.md` during context recovery — it contains accumulated project knowledge and patterns from previous sessions that inform current work.

## Triggers

Activate this skill when you hear:
- "what were we doing", "where were we"
- "continue from last session", "pick up where we left off"
- "what's the status", "what happened"
- "I'm back", "let's continue"
- Any indication of resuming previous work

## Recovery Source Priority

Check these sources in order (stop when you have enough context):

### 1. handoff.md (Most Recent)
```
Location: ./handoff.md or ./.claude/handoff.md
Contains: Last session's summary, pending work, blockers
```

### 2. STATE.md (Project State)
```
Location: ./STATE.md
Contains: Ongoing project state, current phase, key decisions
```

### 3. Git History
```bash
# Recent commits
git log --oneline -10

# What changed recently
git diff HEAD~5 --stat

# Current branch status
git status
```

### 4. Session Logs
```
Location: ./.claude/logs/
Contains: Previous conversation summaries
```

### 5. CLAUDE.md (Project Context)
```
Location: ./CLAUDE.md
Contains: Project conventions, common commands, guidelines
```

## Recovery Report Template

After gathering context, provide this report:

```markdown
## Context Recovery Report

### Last Session Summary
[From handoff.md or STATE.md]

### Current State
- **Branch:** [current git branch]
- **Last Commit:** [most recent commit message]
- **Modified Files:** [any uncommitted changes]

### Work in Progress
- [ ] [Task 1 - status]
- [ ] [Task 2 - status]

### Blockers/Questions
- [Any documented blockers]

### Recommended Next Steps
1. [Most logical next action]
2. [Second priority action]

### Key Decisions Made
- [Important decision 1 and rationale]
- [Important decision 2 and rationale]
```

## Recovery Actions

### If handoff.md exists:
1. Read it completely
2. Summarize the pending work
3. Check if blockers are resolved
4. Propose next steps

### If no handoff.md:
1. Check git log for recent activity
2. Look for uncommitted changes
3. Check for TODO comments in recently modified files
4. Ask user for context if unclear

### If starting fresh:
1. Read CLAUDE.md for project overview
2. Explore project structure
3. Ask user what they want to work on

## Context Handoff Template

When YOU end a session, create/update handoff.md:

```markdown
# Session Handoff - [Date]

## Completed This Session
- [x] [Completed task 1]
- [x] [Completed task 2]

## In Progress
- [ ] [Partial task - current state]

## Blockers
- [Blocker 1 - what's needed to resolve]

## Key Decisions
- **Decision:** [What was decided]
- **Rationale:** [Why]
- **Alternatives Considered:** [What else was considered]

## Files Changed
- `path/to/file.py` - [what changed]

## Next Session Should
1. [First priority]
2. [Second priority]

## Context Notes
[Any other important context for next session]
```

## Recovery Checklist

Before resuming work:
- [ ] Found most recent context source
- [ ] Identified current state of work
- [ ] Listed any blockers
- [ ] Confirmed next steps with user
- [ ] Verified git status is clean (or understood uncommitted changes)
