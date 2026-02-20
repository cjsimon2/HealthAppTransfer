# Accessibility Specialist Review

## Role Context
- **Perspective:** Accessibility expert ensuring inclusive design
- **Expertise:** VoiceOver, Dynamic Type, accessibility APIs
- **Scope:** All user-facing views and interactions
- **Output:** `.claude/reviews/outputs/07-accessibility-specialist-report.md`

## Instructions

Use extended thinking. Review all views for accessibility compliance. Ensure the app is usable by people with various disabilities.

### Methodology
1. Audit VoiceOver support
2. Check Dynamic Type compliance
3. Verify color contrast
4. Review motion and animation
5. Document findings progressively

### Review Order

**Section 1: Navigation & Core UI**
Review main navigation and core screens.
Write findings.

**Section 2: Interactive Elements**
Review buttons, forms, and controls.
Write findings.

**Section 3: Content & Images**
Review text content and images.
Write findings.

**Section 4: Custom Components**
Review custom UI components.
Write findings.

## What to Look For

### VoiceOver (Category: VoiceOver)
- [ ] All interactive elements have labels
- [ ] Labels are concise and descriptive
- [ ] Hints explain non-obvious actions
- [ ] Decorative elements hidden
- [ ] Reading order is logical
- [ ] Custom actions provided where needed
- [ ] Focus management correct for modals

### Dynamic Type (Category: Dynamic Type)
- [ ] All text uses system fonts or @ScaledMetric
- [ ] Text scales without breaking layout
- [ ] Minimum readable at smallest size
- [ ] Layout adapts at largest sizes
- [ ] Touch targets remain adequate

### Color & Contrast (Category: Visual)
- [ ] Contrast ratio meets WCAG 2.1 (4.5:1 for body, 3:1 for large)
- [ ] Information not conveyed by color alone
- [ ] Supports Dark Mode
- [ ] High contrast mode works
- [ ] Focus indicators visible

### Motion (Category: Motion)
- [ ] Respects Reduce Motion setting
- [ ] Alternative transitions available
- [ ] Auto-playing content can be paused
- [ ] No rapidly flashing content

### Touch (Category: Touch)
- [ ] Touch targets at least 44x44pt
- [ ] Adequate spacing between targets
- [ ] Standard gestures used
- [ ] Complex gestures have alternatives

## Output Format

### Finding Example
```markdown
## Finding AX-001: Missing Accessibility Label

- **Severity:** High
- **Category:** VoiceOver
- **File:** `Views/IconButton.swift`
- **Line(s):** 15
- **Description:** Icon button has no accessibility label
- **Impact:** VoiceOver users can't identify button purpose
- **Recommendation:** Add descriptive accessibilityLabel

### Code Reference
```swift
// Current (inaccessible)
Button(action: addItem) {
    Image(systemName: "plus")
}

// Recommended (accessible)
Button(action: addItem) {
    Image(systemName: "plus")
}
.accessibilityLabel("Add item")
```

### Testing Steps
1. Enable VoiceOver
2. Navigate to button
3. Verify meaningful label is spoken
```

## Integration

### Related Commands
- `/accessibility-add` - Add accessibility features

### Related Skills
- `.claude/skills/swiftui-accessibility.md`

### Related Checklists
- `.claude/checklists/accessibility.md`

## Final Report Structure

```markdown
# Accessibility Specialist Review Report

**Project:** HealthAppTransfer
**Review Date:** [Date]
**Reviewer Role:** Accessibility Specialist

## Executive Summary
[Overall accessibility assessment]

## WCAG 2.1 Compliance
| Level | Status |
|-------|--------|
| A | |
| AA | |
| AAA | |

## Findings by Category

### VoiceOver
[Findings]

### Dynamic Type
[Findings]

### Color & Contrast
[Findings]

### Motion
[Findings]

### Touch Targets
[Findings]

## Screen-by-Screen Audit
| Screen | VoiceOver | Dynamic Type | Contrast | Issues |
|--------|-----------|--------------|----------|--------|

## Recommendations
[Prioritized accessibility improvements]

## Testing Checklist
- [ ] VoiceOver navigation complete
- [ ] Dynamic Type at all sizes
- [ ] High Contrast mode
- [ ] Reduce Motion enabled
- [ ] Switch Control compatible
```
