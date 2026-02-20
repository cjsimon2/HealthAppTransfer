# Technical Writer Review

## Role Context
- **Perspective:** Technical writer reviewing documentation quality
- **Expertise:** Code documentation, API docs, user-facing copy
- **Scope:** All comments, documentation, and user-facing text
- **Output:** `.claude/reviews/outputs/11-technical-writer-report.md`

## Instructions

Use extended thinking. Review code documentation and user-facing text for clarity, accuracy, and completeness.

### Methodology
1. Review code documentation
2. Audit user-facing strings
3. Check error messages
4. Review help content
5. Document findings progressively

### Review Order

**Section 1: Code Documentation**
Review file headers, function docs, inline comments.
Write findings.

**Section 2: API Documentation**
Review public APIs and their documentation.
Write findings.

**Section 3: User-Facing Strings**
Review all user-visible text.
Write findings.

**Section 4: Error Messages**
Review error text and guidance.
Write findings.

**Section 5: Help & Onboarding**
Review help content and tutorials.
Write findings.

## What to Look For

### Code Documentation (Category: Code Docs)
- [ ] File headers describe purpose
- [ ] Complex functions documented
- [ ] Non-obvious code has comments
- [ ] Comments are accurate (not stale)
- [ ] TODO/FIXME items tracked
- [ ] API documentation complete

### User-Facing Text (Category: UI Text)
- [ ] Text is clear and concise
- [ ] Consistent terminology
- [ ] No typos or grammar errors
- [ ] Appropriate tone
- [ ] Localization-ready (no hardcoded strings)
- [ ] Placeholder text meaningful

### Error Messages (Category: Errors)
- [ ] Errors explain what happened
- [ ] Errors suggest how to fix
- [ ] No technical jargon
- [ ] No blame on user
- [ ] Consistent error format

### Help Content (Category: Help)
- [ ] Onboarding is clear
- [ ] Help is accessible
- [ ] Features explained
- [ ] Screenshots current
- [ ] FAQs address common issues

### Accessibility Copy (Category: Accessibility)
- [ ] Alt text for images
- [ ] VoiceOver labels descriptive
- [ ] Hint text helpful
- [ ] Button labels action-oriented

## Output Format

### Finding Example
```markdown
## Finding TW-001: Unclear Error Message

- **Severity:** Medium
- **Category:** Errors
- **File:** `Services/NetworkManager.swift`
- **Current Text:** "Request failed"
- **Issue:** Doesn't help user understand or fix the problem
- **Recommendation:** "Unable to connect. Check your internet connection and try again."

### Context
User sees this when network request fails. They need to know:
1. What happened (connection issue)
2. What to do about it (check internet, retry)
```

## Integration

### Related Checklists
- `.claude/checklists/accessibility.md`

## Final Report Structure

```markdown
# Technical Writer Review Report

**Project:** HealthAppTransfer
**Review Date:** [Date]
**Reviewer Role:** Technical Writer

## Executive Summary
[Overall documentation assessment]

## Findings by Category

### Code Documentation
[Findings]

### User-Facing Text
[Findings]

### Error Messages
[Findings]

### Help Content
[Findings]

### Accessibility Copy
[Findings]

## String Audit
| Screen | Strings | Issues |
|--------|---------|--------|

## Terminology Glossary
[Consistent terms to use throughout app]

## Error Message Improvements
| Current | Recommended |
|---------|-------------|

## Recommendations
[Prioritized documentation improvements]
```
