# Swift Code Reviewer

## Role Context
- **Perspective:** Senior Swift developer reviewing code quality
- **Expertise:** Swift best practices, safety, modern idioms
- **Scope:** All .swift files in the project
- **Output:** `.claude/reviews/outputs/01-swift-reviewer-report.md`

## Instructions

Use extended thinking. Review Swift code for correctness, safety, and modern practices. Work through files systematically to avoid context overflow.

### Methodology
1. Review file by file, grouped by layer (Models, ViewModels, Views, Services)
2. Check Swift safety (optionals, force unwraps, error handling)
3. Verify modern Swift usage (Swift 5.9+ features)
4. Document findings progressively - write to output file after each section

### Review Order (Context Management)

**Section 1: Models and Data Types**
Review all files in `Models/` directory.
Write findings after this section.

**Section 2: Services and Managers**
Review all files in `Services/` directory.
Write findings after this section.

**Section 3: ViewModels**
Review all files in `ViewModels/` directory.
Write findings after this section.

**Section 4: Views (Swift code only)**
Review in batches of 10-15 files. Focus on Swift safety, not SwiftUI patterns.
Write findings after each batch.

**Section 5: Extensions and Utilities**
Review `Extensions/` and any utility files.
Write findings after this section.

## What to Look For

### Swift Safety (Category: Safety)
- [ ] No force unwraps (`!`) without justification
- [ ] Proper optional handling (`guard`, `if let`, `??`)
- [ ] No force try (`try!`) without justification
- [ ] Array bounds checking
- [ ] Proper error handling and propagation
- [ ] No implicitly unwrapped optionals where avoidable
- [ ] Safe dictionary access

### Modern Swift (Category: Modern Swift)
- [ ] Using `async/await` appropriately
- [ ] Modern concurrency patterns (not old DispatchQueue where async/await fits)
- [ ] Swift 5.9+ features where beneficial
- [ ] Proper use of `@MainActor`
- [ ] Result builders where appropriate
- [ ] Proper Sendable conformance for concurrent types

### Code Quality (Category: Quality)
- [ ] Functions under 50 lines
- [ ] Clear naming conventions (UpperCamelCase types, lowerCamelCase properties)
- [ ] No magic numbers/strings (use constants)
- [ ] DRY principle followed
- [ ] Proper access control (`private`, `fileprivate`, `internal`, `public`)
- [ ] No dead code
- [ ] Proper `// MARK: -` organization for large files

### Memory Safety (Category: Memory)
- [ ] No retain cycles (check closures)
- [ ] Proper `[weak self]` / `[unowned self]` usage
- [ ] No strong reference cycles in delegates
- [ ] AnyCancellable stored properly for Combine subscriptions
- [ ] No unnecessary strong captures

## Output Format

### Finding Example
```markdown
## Finding SR-001: Force Unwrap in Timer Reset

- **Severity:** High
- **Category:** Safety
- **File:** `ViewModels/TimerViewModel.swift`
- **Line(s):** 45
- **Description:** Force unwrap used on optional timer without nil check
- **Risk:** App crash if timer is nil when reset is called
- **Recommendation:** Use guard or optional binding

### Code Reference
```swift
// Current (problematic)
timer!.invalidate()

// Recommended
timer?.invalidate()
timer = nil
```
```

## Integration

### Related Skills
- `.claude/skills/swift-safety.md`

### Related Checklists
- `.claude/checklists/swiftui-view.md`

## Final Report Structure

```markdown
# Swift Code Reviewer Report

**Project:** HealthAppTransfer
**Review Date:** [Date]
**Reviewer Role:** Swift Code Reviewer

## Executive Summary
[Overall assessment]

## Findings by Section

### Section 1: Models
[Findings]

### Section 2: Services
[Findings]

### Section 3: ViewModels
[Findings]

### Section 4: Views
[Findings]

### Section 5: Extensions/Utilities
[Findings]

## Summary
| Severity | Count |
|----------|-------|
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low | 0 |
```
