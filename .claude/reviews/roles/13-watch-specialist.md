# watchOS Specialist Review

## Role Context
- **Perspective:** watchOS expert reviewing Watch app
- **Expertise:** watchOS development, Watch connectivity, complications
- **Scope:** All Watch app code and connectivity
- **Output:** `.claude/reviews/outputs/13-watch-specialist-report.md`

## Instructions

Use extended thinking. Review the Watch app implementation for best practices, performance, and iOS connectivity.

### Methodology
1. Review Watch app structure
2. Audit complications
3. Check connectivity
4. Review performance
5. Document findings progressively

### Review Order

**Section 1: App Structure**
Review Watch app entry point and navigation.
Write findings.

**Section 2: Views & UI**
Review Watch-specific UI patterns.
Write findings.

**Section 3: Complications**
Review complication implementation.
Write findings.

**Section 4: Connectivity**
Review Watch-iPhone communication.
Write findings.

**Section 5: Performance**
Review Watch-specific performance.
Write findings.

## What to Look For

### App Structure (Category: Structure)
- [ ] Proper WatchKit app structure
- [ ] Correct Info.plist configuration
- [ ] Appropriate capabilities enabled
- [ ] Shared code properly organized
- [ ] Watch-specific assets included

### UI Patterns (Category: UI)
- [ ] Glanceable information design
- [ ] Appropriate touch targets
- [ ] Digital Crown support where appropriate
- [ ] Compact layouts for small screen
- [ ] List-based navigation

### Complications (Category: Complications)
- [ ] All complication families supported
- [ ] Timeline provider efficient
- [ ] Refresh strategy appropriate
- [ ] Placeholder data meaningful
- [ ] Deep links work

### Connectivity (Category: Connectivity)
- [ ] WCSession properly configured
- [ ] Activation state handled
- [ ] Message/data transfer appropriate
- [ ] Offline capability
- [ ] Sync conflicts handled

### Performance (Category: Performance)
- [ ] Memory usage under 30MB
- [ ] Background tasks efficient
- [ ] Network requests minimal
- [ ] Animations smooth
- [ ] Launch time quick

## Output Format

### Finding Example
```markdown
## Finding WS-001: Missing Complication Family

- **Severity:** Medium
- **Category:** Complications
- **File:** `Widget/WatchComplication.swift`
- **Description:** accessoryCorner family not supported
- **Impact:** Users can't use complication in corner slot
- **Recommendation:** Add accessoryCorner to supported families

### Code Reference
```swift
// Current
.supportedFamilies([
    .accessoryCircular,
    .accessoryRectangular
])

// Recommended
.supportedFamilies([
    .accessoryCircular,
    .accessoryRectangular,
    .accessoryCorner,
    .accessoryInline
])
```
```

## Integration

### Related Skills
- `.claude/skills/watchos-patterns.md`

## Final Report Structure

```markdown
# watchOS Specialist Review Report

**Project:** HealthAppTransfer
**Review Date:** [Date]
**Reviewer Role:** watchOS Specialist

## Executive Summary
[Overall Watch app assessment]

## Findings by Category

### App Structure
[Findings]

### UI Patterns
[Findings]

### Complications
[Findings]

### Connectivity
[Findings]

### Performance
[Findings]

## Complication Audit
| Family | Supported | Issues |
|--------|-----------|--------|
| accessoryCircular | | |
| accessoryRectangular | | |
| accessoryCorner | | |
| accessoryInline | | |

## Connectivity Matrix
| Feature | Send | Receive | Sync Status |
|---------|------|---------|-------------|

## Performance Metrics
| Metric | Current | Target |
|--------|---------|--------|
| Memory | | <30MB |
| Launch | | <2s |

## Recommendations
[Prioritized Watch improvements]
```
