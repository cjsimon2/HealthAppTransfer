# iOS Architect Review

## Role Context
- **Perspective:** iOS architect evaluating system design
- **Expertise:** MVVM, Combine, SwiftData, app architecture
- **Scope:** Overall architecture and design patterns
- **Output:** `.claude/reviews/outputs/03-architect-report.md`

## Instructions

Use extended thinking. Evaluate the architecture holistically. Is MVVM implemented consistently? Is the data layer solid? Will this scale?

### Methodology
1. Map the architecture layers
2. Verify MVVM compliance across all features
3. Audit Combine usage patterns
4. Review data persistence integration
5. Check dependency management
6. Document findings progressively

### Review Order

**Section 1: Architecture Overview**
Read core files to understand the architecture:
- App entry point
- Main navigation structure
- Core services/singletons
Map the high-level architecture. Write initial assessment.

**Section 2: MVVM Compliance - ViewModels**
Review all ViewModels for proper separation of concerns.
Verify ViewModels contain business logic, not views. Write findings.

**Section 3: MVVM Compliance - Views (Sample)**
Check a representative sample of views for MVVM compliance.
Write findings.

**Section 4: Combine Architecture**
Check Combine patterns in ViewModels and Services.
Write findings.

**Section 5: Data Architecture**
Review models and persistence layer.
Write findings.

**Section 6: Dependency Management**
Review how dependencies are injected/accessed.
Write findings.

## What to Look For

### MVVM Compliance (Category: MVVM)
- [ ] Views are passive (no business logic in view body)
- [ ] ViewModels contain business logic
- [ ] Models are data only (no business logic, no UI code)
- [ ] Clear separation of concerns
- [ ] No view code in ViewModels (no Color, no View types)
- [ ] Proper dependency injection

### Combine Architecture (Category: Combine)
- [ ] Publishers properly defined (@Published properties)
- [ ] Subscriptions stored in AnyCancellable
- [ ] No subscription leaks
- [ ] Proper threading with `receive(on:)` or `@MainActor`
- [ ] Error handling in pipelines
- [ ] No excessive Combine complexity

### Data Architecture (Category: Data)
- [ ] Data models well-designed
- [ ] Relationships properly defined
- [ ] Queries efficient
- [ ] CloudKit sync safe (if applicable)
- [ ] Migration path clear for future changes

### Scalability (Category: Scalability)
- [ ] Easy to add new features
- [ ] Easy to modify existing features
- [ ] No tight coupling between unrelated components
- [ ] Testable design (dependencies injectable)
- [ ] Clear module boundaries

### Singleton Usage (Category: Dependency)
- [ ] Singletons used appropriately (truly global state)
- [ ] Not overusing singletons
- [ ] Proper initialization order
- [ ] Thread-safe singleton access

## Output Format

### Finding Example
```markdown
## Finding AR-001: Business Logic in View

- **Severity:** Medium
- **Category:** MVVM
- **File:** `Views/PlannerView.swift`
- **Line(s):** 145-160
- **Description:** Filtering and sorting logic implemented directly in view body
- **Risk:** Makes view harder to test, violates MVVM separation
- **Recommendation:** Move filtering/sorting to ViewModel

### Code Reference
```swift
// Current (in view body)
let filteredItems = items.filter { $0.dueDate > Date() }.sorted { ... }

// Recommended (in viewmodel)
var upcomingItems: [Item] {
    items.filter { $0.dueDate > Date() }.sorted { ... }
}
```
```

## Additional Output

### Architecture Diagram
```
┌─────────────────────────────────────────────────┐
│                   Views Layer                    │
│    ContentView, HomeView, DetailView, ...       │
└─────────────────────────┬───────────────────────┘
                          │ @ObservedObject / @StateObject
┌─────────────────────────▼───────────────────────┐
│                 ViewModel Layer                  │
│    ViewModels + Singleton Services              │
└─────────────────────────┬───────────────────────┘
                          │
┌─────────────────────────▼───────────────────────┐
│                   Data Layer                     │
│    SwiftData Models, Repositories               │
└─────────────────────────┬───────────────────────┘
                          │
┌─────────────────────────▼───────────────────────┐
│                Persistence Layer                 │
│         SwiftData + CloudKit / UserDefaults     │
└─────────────────────────────────────────────────┘
```

## Integration

### Related Commands
- `/combine-check` - Combine review

### Related Skills
- `.claude/skills/mvvm-patterns.md`
- `.claude/skills/combine-patterns.md`

## Final Report Structure

```markdown
# iOS Architect Review Report

**Project:** HealthAppTransfer
**Review Date:** [Date]
**Reviewer Role:** iOS Architect

## Executive Summary
[Overall architecture assessment]

## Architecture Diagram
[ASCII diagram]

## MVVM Compliance
### Compliance Matrix
| ViewModel | View(s) | Issues |
|-----------|---------|--------|

### Findings
[Detailed findings]

## Combine Architecture
[Findings]

## Data Architecture
[Findings]

## Scalability Assessment
[Analysis]

## Recommendations
[Prioritized improvements]
```
