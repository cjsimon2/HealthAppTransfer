---
name: verify-before-complete
description: This skill should be used when the user says "done", "finished", "complete", "that should do it", "all set", "ready for review", "ready for QA", or any claim of task completion. Ensures work is verified before marking complete.
memory:
  scope: project
---

# Verify Before Complete

Ensures work is actually complete before marking it done.

## Triggers

Activate this skill when you hear:
- "done", "finished", "complete", "completed"
- "that should do it", "all set"
- "ready for review", "ready for QA"
- Any claim of task completion

## Requirements Before Marking Complete

You MUST have evidence for each of these before claiming completion:

### 1. Changes Evidence
```
- [ ] List ALL files modified/created
- [ ] Each change has a clear purpose
- [ ] No unintended changes included
```

### 2. Verification Evidence
```
- [ ] Build/compile passes (show output)
- [ ] Tests pass (show output)
- [ ] Manual verification done (describe what was tested)
```

### 3. Acceptance Criteria Status
```
For EACH acceptance criterion:
- [ ] Criterion text: [copy it]
- [ ] Status: Met / Not Met / Partially Met
- [ ] Evidence: [code snippet or test output proving it]
```

## Verification Checklist Template

Before saying "done", fill out this checklist:

```markdown
### Completion Verification

**Task:** [What was the task?]

**Files Changed:**
- `path/file.py` - [what changed]

**Build Status:** ✅ Passing / ❌ Failing
```
[paste build output or error]
```

**Test Status:** ✅ All passing / ❌ Failures
```
[paste test output]
```

**Acceptance Criteria:**
1. [Criterion 1]: ✅ Met
   - Evidence: [code snippet or test]
2. [Criterion 2]: ✅ Met
   - Evidence: [code snippet or test]

**Manual Verification:**
- [What was manually tested and result]

**Ready for QA:** Yes / No (if no, explain what's blocking)
```

## What Incomplete Looks Like

Do NOT claim completion if:
- Build is failing
- Tests are failing
- Any acceptance criterion lacks evidence
- You haven't actually run verification commands
- You're assuming something works without checking

## Escalation

If you cannot complete verification:
1. Document what's blocking
2. List what would be needed to verify
3. Mark as "partially complete" or "blocked"
4. Do NOT claim it's done
