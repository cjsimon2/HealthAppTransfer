# Widget Specialist Review

## Role Context
- **Perspective:** WidgetKit expert reviewing widget implementation
- **Expertise:** WidgetKit, timelines, widget configuration
- **Scope:** All widget code and data sharing
- **Output:** `.claude/reviews/outputs/14-widget-specialist-report.md`

## Instructions

Use extended thinking. Review the widget implementation for best practices, efficiency, and user experience.

### Methodology
1. Review widget structure
2. Audit timeline provider
3. Check data sharing
4. Review widget families
5. Document findings progressively

### Review Order

**Section 1: Widget Configuration**
Review widget definition and configuration.
Write findings.

**Section 2: Timeline Provider**
Review timeline generation and refresh.
Write findings.

**Section 3: Widget Views**
Review widget UI for all sizes.
Write findings.

**Section 4: Data Sharing**
Review App Group and data access.
Write findings.

**Section 5: Interactivity (iOS 17+)**
Review interactive widget features.
Write findings.

## What to Look For

### Configuration (Category: Configuration)
- [ ] Widget kind unique and descriptive
- [ ] Display name and description clear
- [ ] Supported families appropriate
- [ ] Configuration intent (if applicable)
- [ ] Proper bundle setup

### Timeline (Category: Timeline)
- [ ] Placeholder provides meaningful preview
- [ ] Snapshot fast and lightweight
- [ ] Timeline entries efficient
- [ ] Refresh policy appropriate
- [ ] Not over-requesting updates

### Views (Category: Views)
- [ ] All supported sizes implemented
- [ ] Content adapts to size
- [ ] Glanceable information
- [ ] Deep links functional
- [ ] Redacted placeholder appropriate

### Data Sharing (Category: Data)
- [ ] App Group configured
- [ ] Shared UserDefaults used correctly
- [ ] Core Data/SwiftData accessible
- [ ] Data freshness reasonable
- [ ] Error states handled

### Interactivity (Category: Interactive)
- [ ] Buttons/toggles work (iOS 17+)
- [ ] App Intents configured
- [ ] Immediate visual feedback
- [ ] State updates correctly
- [ ] Fallback for older iOS

## Output Format

### Finding Example
```markdown
## Finding WG-001: Excessive Timeline Refresh

- **Severity:** Medium
- **Category:** Timeline
- **File:** `Widget/Provider.swift`
- **Description:** Timeline refreshes every 5 minutes
- **Impact:** Battery drain, system may throttle widget
- **Recommendation:** Increase refresh interval based on data change frequency

### Code Reference
```swift
// Current (too frequent)
let nextUpdate = Date().addingTimeInterval(5 * 60)
let timeline = Timeline(entries: entries, policy: .after(nextUpdate))

// Recommended (hourly for most widgets)
let nextUpdate = Date().addingTimeInterval(60 * 60)
let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
```

### Best Practice
- Only refresh when data changes
- Use .atEnd for static content
- Consider user's update expectations
```

## Integration

### Related Commands
- `/widget-review` - Widget implementation review

### Related Skills
- `.claude/skills/widget-patterns.md`

## Final Report Structure

```markdown
# Widget Specialist Review Report

**Project:** HealthAppTransfer
**Review Date:** [Date]
**Reviewer Role:** Widget Specialist

## Executive Summary
[Overall widget assessment]

## Findings by Category

### Configuration
[Findings]

### Timeline
[Findings]

### Views
[Findings]

### Data Sharing
[Findings]

### Interactivity
[Findings]

## Widget Family Support
| Family | Supported | Preview | Issues |
|--------|-----------|---------|--------|
| systemSmall | | | |
| systemMedium | | | |
| systemLarge | | | |
| accessoryCircular | | | |
| accessoryRectangular | | | |
| accessoryInline | | | |

## Timeline Analysis
| Widget | Refresh Rate | Entries | Issues |
|--------|--------------|---------|--------|

## Deep Link Audit
| Widget | Tap Target | URL | Works |
|--------|------------|-----|-------|

## Recommendations
[Prioritized widget improvements]
```
