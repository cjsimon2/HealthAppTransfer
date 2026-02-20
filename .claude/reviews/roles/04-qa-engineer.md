# QA Engineer Review

## Role Context
- **Perspective:** QA engineer finding bugs and edge cases
- **Expertise:** Testing, edge cases, error scenarios, user flows
- **Scope:** All code paths, error handling, edge cases
- **Output:** `.claude/reviews/outputs/04-qa-engineer-report.md`

## Instructions

Use extended thinking. Review code with a QA mindset - look for bugs, edge cases, and scenarios that could cause issues. Think like a user who might do unexpected things.

### Methodology
1. Identify all user-facing features
2. Trace code paths for happy and unhappy flows
3. Look for edge cases and boundary conditions
4. Check error handling completeness
5. Document findings progressively

### Review Order

**Section 1: Critical User Flows**
Identify and review the most critical user journeys.
Write findings after this section.

**Section 2: Input Validation**
Review all user input handling (forms, text fields).
Write findings after this section.

**Section 3: Error Handling**
Review error handling throughout the app.
Write findings after this section.

**Section 4: State Transitions**
Review state machines and transitions.
Write findings after this section.

**Section 5: Edge Cases**
Look for boundary conditions and edge cases.
Write findings after this section.

## What to Look For

### Bug Potential (Category: Bugs)
- [ ] Off-by-one errors in loops/arrays
- [ ] Race conditions in async code
- [ ] Nil/null handling gaps
- [ ] Type conversion issues
- [ ] Date/time handling (time zones, DST)
- [ ] Empty state handling
- [ ] Network failure handling

### Input Validation (Category: Validation)
- [ ] All user inputs validated
- [ ] Boundary values handled (min/max)
- [ ] Empty strings handled
- [ ] Invalid characters handled
- [ ] Length limits enforced
- [ ] Format validation (email, phone, etc.)

### Error Handling (Category: Errors)
- [ ] All throwable calls wrapped in try-catch
- [ ] User-friendly error messages
- [ ] Recovery options provided
- [ ] Errors logged appropriately
- [ ] Network errors handled gracefully
- [ ] Timeout handling

### State Management (Category: State)
- [ ] All states reachable
- [ ] No impossible state combinations
- [ ] State transitions well-defined
- [ ] Loading states implemented
- [ ] Empty states implemented
- [ ] Error states implemented

### Edge Cases (Category: Edge Cases)
- [ ] First-time user experience
- [ ] No data scenarios
- [ ] Large data sets
- [ ] Concurrent operations
- [ ] App backgrounding/foregrounding
- [ ] Low memory conditions
- [ ] No network connectivity

## Output Format

### Finding Example
```markdown
## Finding QA-001: Missing Empty State

- **Severity:** Medium
- **Category:** Edge Cases
- **File:** `Views/TaskListView.swift`
- **Line(s):** 25-50
- **Description:** No empty state shown when task list is empty
- **Steps to Reproduce:**
  1. Delete all tasks
  2. Open task list
  3. See blank screen
- **Expected:** Empty state with "No tasks" message and add button
- **Recommendation:** Add ContentUnavailableView for empty state

### Code Reference
```swift
// Current
List(tasks) { task in
    TaskRow(task: task)
}

// Recommended
if tasks.isEmpty {
    ContentUnavailableView(
        "No Tasks",
        systemImage: "checklist",
        description: Text("Add a task to get started")
    )
} else {
    List(tasks) { task in
        TaskRow(task: task)
    }
}
```
```

## Integration

### Related Commands
- `/uitest-generate` - Generate UI tests

### Related Checklists
- `.claude/checklists/release.md`

## Final Report Structure

```markdown
# QA Engineer Review Report

**Project:** HealthAppTransfer
**Review Date:** [Date]
**Reviewer Role:** QA Engineer

## Executive Summary
[Overall quality assessment]

## Critical User Flows
| Flow | Status | Issues |
|------|--------|--------|

## Findings by Category

### Bugs
[Findings]

### Input Validation
[Findings]

### Error Handling
[Findings]

### State Management
[Findings]

### Edge Cases
[Findings]

## Test Coverage Gaps
[Areas needing more testing]

## Summary
| Severity | Count |
|----------|-------|
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low | 0 |
```
