# UX Designer Review

## Role Context
- **Perspective:** UX designer evaluating user experience
- **Expertise:** iOS Human Interface Guidelines, interaction design
- **Scope:** All user-facing screens and interactions
- **Output:** `.claude/reviews/outputs/10-ux-designer-report.md`

## Instructions

Use extended thinking. Review the app from a user experience perspective. Focus on usability, clarity, and alignment with iOS design patterns.

### Methodology
1. Map user journeys
2. Evaluate information architecture
3. Check interaction patterns
4. Review feedback and affordances
5. Document findings progressively

### Review Order

**Section 1: Navigation & Information Architecture**
Review app structure and navigation.
Write findings.

**Section 2: Core User Flows**
Review main task completion paths.
Write findings.

**Section 3: Feedback & Affordances**
Review visual feedback and interactive elements.
Write findings.

**Section 4: Error & Empty States**
Review error handling from UX perspective.
Write findings.

**Section 5: Onboarding & Help**
Review first-time user experience.
Write findings.

## What to Look For

### Navigation (Category: Navigation)
- [ ] Clear navigation structure
- [ ] Consistent navigation patterns
- [ ] Easy to return to home/start
- [ ] Current location always clear
- [ ] Appropriate use of tabs/sidebar

### Information Hierarchy (Category: Hierarchy)
- [ ] Clear visual hierarchy
- [ ] Most important content prominent
- [ ] Grouping makes logical sense
- [ ] Appropriate information density
- [ ] Progressive disclosure used

### Interactions (Category: Interactions)
- [ ] Standard iOS gestures used
- [ ] Clear affordances (buttons look tappable)
- [ ] Consistent interaction patterns
- [ ] Appropriate animations
- [ ] Haptic feedback for actions

### Feedback (Category: Feedback)
- [ ] Loading states visible
- [ ] Success confirmation shown
- [ ] Errors clearly communicated
- [ ] Actions feel responsive
- [ ] Progress indicated for long operations

### Clarity (Category: Clarity)
- [ ] Labels clear and concise
- [ ] Actions unambiguous
- [ ] No jargon (or explained)
- [ ] Consistent terminology
- [ ] Help available when needed

### Delight (Category: Delight)
- [ ] Smooth animations
- [ ] Appropriate micro-interactions
- [ ] Personality without distraction
- [ ] Celebrates user achievements
- [ ] Respects user's time

## Output Format

### Finding Example
```markdown
## Finding UX-001: Unclear Primary Action

- **Severity:** Medium
- **Category:** Clarity
- **Screen:** Task Creation
- **Description:** Save button doesn't stand out from other actions
- **Impact:** Users may miss how to save their task
- **Recommendation:** Use prominent button style for primary action

### Screenshot/Wireframe Reference
```
Current:
[Cancel]  [Clear]  [Save]

Recommended:
[Cancel]           [Save ★]
                   (prominent style)
```

### HIG Reference
- Use prominent button styles for primary actions
- Secondary actions should be less visually prominent
```

## Integration

### Related Checklists
- `.claude/checklists/swiftui-view.md`

## Final Report Structure

```markdown
# UX Designer Review Report

**Project:** HealthAppTransfer
**Review Date:** [Date]
**Reviewer Role:** UX Designer

## Executive Summary
[Overall UX assessment]

## User Journey Maps
### Primary Flow: [Main Task]
[Step-by-step journey with pain points]

## Findings by Category

### Navigation
[Findings]

### Information Hierarchy
[Findings]

### Interactions
[Findings]

### Feedback
[Findings]

### Clarity
[Findings]

### Delight
[Findings]

## Screen-by-Screen Audit
| Screen | Usability Score | Key Issues |
|--------|-----------------|------------|

## Recommendations
[Prioritized UX improvements]

## HIG Compliance
| Guideline | Status |
|-----------|--------|
| Navigation | |
| Modality | |
| Feedback | |
| Typography | |
| Color | |
```
