# SwiftUI Specialist Review

## Role Context
- **Perspective:** SwiftUI expert reviewing UI implementation
- **Expertise:** SwiftUI patterns, performance, state management
- **Scope:** All SwiftUI views and related code
- **Output:** `.claude/reviews/outputs/02-swiftui-specialist-report.md`

## Instructions

Use extended thinking. Review all SwiftUI code for correctness, performance, and modern patterns. Review systematically by feature area to manage context.

### Methodology
1. Review views by feature area
2. Check state management patterns
3. Audit view performance
4. Verify preview completeness
5. Document findings progressively after each feature area

### Review Order (by Layer)

**Section 1: Core Navigation & App Structure**
Review root views, tab views, navigation containers.
Write findings after this section.

**Section 2: Main Feature Views**
Review primary feature views.
Write findings after this section.

**Section 3: Detail & Form Views**
Review detail screens and forms.
Write findings after this section.

**Section 4: Shared Components**
Review reusable components.
Write findings after this section.

## What to Look For

### State Management (Category: State)
- [ ] Correct property wrapper usage (@State, @Binding, @StateObject, @ObservedObject, @EnvironmentObject)
- [ ] @StateObject only for owned objects (created in that view)
- [ ] @ObservedObject for injected objects and singletons
- [ ] No @State for reference types (classes)
- [ ] Proper @Environment usage
- [ ] State at appropriate level (not too high causing unnecessary re-renders)

### View Performance (Category: Performance)
- [ ] Views are small and focused (single responsibility)
- [ ] Heavy computation NOT in view body
- [ ] Images optimized (resizable, proper sizing, async loading)
- [ ] Lists use proper identification (id parameter or Identifiable)
- [ ] LazyVStack/LazyHStack where appropriate for large collections
- [ ] No unnecessary re-renders
- [ ] Equatable conformance where beneficial

### Animations (Category: Animation)
- [ ] Animations are smooth (no hitches or dropped frames)
- [ ] withAnimation used correctly
- [ ] Animation timing appropriate for context
- [ ] Reduced motion respected (`@Environment(\.accessibilityReduceMotion)`)
- [ ] No animation jank during scrolling

### Modern SwiftUI (Category: Modern)
- [ ] iOS 17+ features used where beneficial
- [ ] @Observable consideration (migration from ObservableObject)
- [ ] Modern navigation (NavigationStack, not deprecated NavigationView)
- [ ] Proper sheet/fullScreenCover usage
- [ ] New container types (ContentUnavailableView, etc.)

### Previews (Category: Preview)
- [ ] All views have previews
- [ ] Previews show multiple states (empty, loading, populated, error)
- [ ] Preview data is realistic
- [ ] Previews compile and render
- [ ] Preview modifiers used correctly

### Layout (Category: Layout)
- [ ] Consistent spacing scale (8, 16, 24, 32)
- [ ] Bottom padding for tab bar where needed
- [ ] Safe area handling
- [ ] iPad layout considered (split view, sidebar)

## Output Format

### Finding Example
```markdown
## Finding SU-001: @State Used for Singleton

- **Severity:** High
- **Category:** State
- **File:** `Views/HomeView.swift`
- **Line(s):** 12
- **Description:** @State used for AppSettings.shared which is a reference type singleton
- **Risk:** State changes won't trigger view updates correctly
- **Recommendation:** Use @ObservedObject for shared singletons

### Code Reference
```swift
// Current (problematic)
@State var settings = AppSettings.shared

// Recommended
@ObservedObject var settings = AppSettings.shared
```
```

## Integration

### Related Commands
- `/view-audit` - Single view audit
- `/state-review` - State management review

### Related Skills
- `.claude/skills/swiftui-patterns.md`
- `.claude/skills/swiftui-performance.md`

### Related Checklists
- `.claude/checklists/swiftui-view.md`

## Final Report Structure

```markdown
# SwiftUI Specialist Review Report

**Project:** HealthAppTransfer
**Review Date:** [Date]
**Reviewer Role:** SwiftUI Specialist

## Executive Summary
[Overall assessment]

## Findings by Section

### Section 1: Core Navigation
[Findings]

### Section 2: Main Features
[Findings]

### Section 3: Detail & Forms
[Findings]

### Section 4: Shared Components
[Findings]

## State Management Matrix
| View | Wrappers Used | Issues |
|------|---------------|--------|

## Summary
| Category | Issues Found |
|----------|--------------|
| State | 0 |
| Performance | 0 |
| Animation | 0 |
| Modern | 0 |
| Preview | 0 |
| Layout | 0 |
```
