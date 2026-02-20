# Check Your Work

Perform a thorough self-review before committing. This command verifies code quality AND ensures all tracking files (STATE.md, LEARNINGS.md, etc.) are accurate and up-to-date.

## CRITICAL: Output Format

**You MUST produce your final report using this EXACT format with tables, checkmarks (✅/❌), AND explanatory sentences under each table.**

---

## Instructions

1. **Gather context** - Run `git status` and `git diff` to see what changed
2. **Perform each check** - Actually run commands, read files, verify each item
3. **Scan all .md files** - Check STATE.md, LEARNINGS.md, and any tracking files for accuracy
4. **Fix issues** - Don't just report problems, AUTO-FIX them immediately
5. **Update tracking files** - Add checkmarks to completed items, update statuses
6. **Produce the report** - Use the EXACT format below with explanations UNDER each table

---

## Checks to Perform

### Code Quality

| Check | How to Verify |
|-------|---------------|
| Build/Compile | Run build command, confirm no errors |
| No Debug Code | Search for console.log, print(), debugger |
| No Commented Code | Look for blocks of commented-out code |
| No Unused Imports | Check each modified file |
| Follows Patterns | Compare with similar existing files |

Ensures the code is production-ready by catching common development artifacts that shouldn't be committed. Debug statements, commented-out code blocks, and unused imports add noise and can cause issues in production.

### Testing

| Check | How to Verify |
|-------|---------------|
| Tests Pass | Run test suite (pytest, npm test, etc.) |
| New Code Has Tests | Check coverage for new functionality |
| Edge Cases | Null inputs, empty arrays, boundaries |

Verifies that new code is properly tested and doesn't break existing functionality. Every new feature or bug fix should have corresponding tests, including edge cases that might cause unexpected behavior.

### Security

| Check | How to Verify |
|-------|---------------|
| No Secrets | Search for password, api_key, token, secret |
| SQL Injection | Verify parameterized queries |
| Input Validation | User input is validated/escaped |

Catches security vulnerabilities before they reach the codebase. Hardcoded secrets are a critical risk, and unvalidated user input is the most common attack vector for web applications.

### Anti-Overengineering

| Check | How to Verify |
|-------|---------------|
| No Single-Use Abstractions | Helpers used more than once? |
| No Just-in-Case Code | Features actually needed now? |
| No Scope Creep | Only changed what was requested? |

Guards against unnecessary complexity that makes code harder to maintain. Abstractions should earn their place by being reused, and features should be built when needed rather than speculatively.

### Documentation

| Check | How to Verify |
|-------|---------------|
| Public APIs Documented | New functions have docstrings |
| Complex Logic Explained | Non-obvious code has comments |

Ensures future developers (including yourself) can understand the code without reverse-engineering it. Public APIs need docstrings; complex logic needs inline comments explaining the "why."

### Markdown File Verification

**IMPORTANT: Scan ALL .md tracking files in the project.**

| Check | How to Verify |
|-------|---------------|
| STATE.md Accurate | Task statuses match actual completion |
| Completed Tasks Have ✅ | All finished work is marked done |
| Active Tasks Updated | In-progress tasks reflect current state |
| LEARNINGS.md Current | Recent insights are documented |
| Blockers Cleared | Resolved blockers are removed |
| Metrics Updated | Test/build status reflects reality |

Keeps project tracking files synchronized with actual progress. Stale documentation causes confusion during handoffs and makes it hard to assess project status accurately.

**AUTO-FIX these issues when found:**
- Add ✅ checkmarks to completed items that are missing them
- Update task statuses from "In Progress" to "Completed" for finished work
- Remove resolved blockers from the blockers section
- Update metrics (Tests, Build status) based on actual results
- Move completed tasks from Active to Completed section

---

## REQUIRED Output Format

**After completing all checks, you MUST produce this report with explanatory sentences UNDER each table:**

```
## Check Your Work Report

### Files Reviewed

| File | Changes |
|------|---------|
| `path/to/file.py` | Brief description of changes |
| `path/to/other.ts` | Brief description of changes |

Reviewed all modified files from the current git diff. Each file was examined for code quality, security issues, and adherence to project patterns.

### Code Quality

| Check | Status | Notes |
|-------|--------|-------|
| Build/Compile | ✅ | Passed |
| No Debug Code | ✅ | Clean |
| No Commented Code | ✅ | Clean |
| No Unused Imports | ❌ | Found in file.py - FIXED |
| Follows Patterns | ✅ | Consistent |

Ran the build command successfully with no errors. Searched for debug statements and found none. Removed one unused import from file.py that was left over from earlier development.

### Testing

| Check | Status | Notes |
|-------|--------|-------|
| Tests Pass | ✅ | 24 passed, 0 failed |
| New Code Has Tests | ✅ | 6 new tests added |
| Edge Cases | ✅ | Covered |

Executed the full test suite. All 24 tests passed. The new functionality has 6 dedicated tests covering the main paths and edge cases including null inputs and boundary conditions.

### Security

| Check | Status | Notes |
|-------|--------|-------|
| No Secrets | ✅ | Clean |
| SQL Injection | ✅ | N/A - no database queries |
| Input Validation | ✅ | Present |

Scanned for hardcoded secrets (passwords, API keys, tokens) and found none. No SQL queries in the changed files. User input validation is properly implemented using the existing sanitization utilities.

### Anti-Overengineering

| Check | Status | Notes |
|-------|--------|-------|
| No Single-Use Abstractions | ✅ | Clean |
| No Just-in-Case Code | ✅ | Clean |
| No Scope Creep | ✅ | Focused changes |

All helper functions are used more than once. No speculative features were added. Changes stayed focused on the original request without expanding scope.

### Documentation

| Check | Status | Notes |
|-------|--------|-------|
| Public APIs Documented | ✅ | Docstrings added |
| Complex Logic Explained | ✅ | Comments where needed |

Added docstrings to the two new public functions. Added a brief comment explaining the caching logic which isn't immediately obvious.

### Markdown File Verification

| File | Status | Issues Found | Action Taken |
|------|--------|--------------|--------------|
| STATE.md | ✅ | Task X was done but not marked | Added ✅, moved to Completed |
| LEARNINGS.md | ✅ | None | Current |
| handoff.md | ✅ | None | N/A |

Scanned all tracking markdown files. Found that "Implement user login" was completed but still listed under Active Tasks. Moved it to Completed Tasks section and added the completion checkmark. Updated the test metrics to reflect the passing test suite.

### Issues Found & Fixed

| # | Category | Issue | Fix |
|---|----------|-------|-----|
| 1 | Code Quality | Unused import in file.py:3 | Removed ✅ |
| 2 | MD Verification | Task not marked complete in STATE.md | Updated status ✅ |
| 3 | MD Verification | Test metrics outdated | Updated to "24 passed" ✅ |

Fixed 3 issues total: 1 code quality issue and 2 markdown tracking inconsistencies. All issues were auto-fixed.

### Summary

| Metric | Value |
|--------|-------|
| Files Reviewed | 4 |
| Checks Passed | 16 |
| Checks Failed | 0 |
| Issues Fixed | 3 |
| MD Files Verified | 3 |
| **Ready to Commit** | ✅ YES |

All code quality checks pass. All tracking files are now accurate and up-to-date. The codebase is ready for commit.
```

---

## Important Rules

1. **Use ✅ for passing checks, ❌ for failing checks**
2. **Use tables for ALL sections** - not bullet lists
3. **Include explanatory sentences UNDER each table** - describe what was checked and what was done
4. **Fix issues before reporting** - then mark as "FIXED" with ✅
5. **AUTO-FIX markdown files** - don't just report problems, actually update the files
6. **Be specific** - include file paths and line numbers
7. **Include the Summary table** at the end with Ready to Commit status
8. **Verify ALL .md tracking files** - STATE.md, LEARNINGS.md, handoff.md, etc.
