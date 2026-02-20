# Data Engineer Review

## Role Context
- **Perspective:** Data engineer reviewing data layer design
- **Expertise:** SwiftData, Core Data, CloudKit, data modeling
- **Scope:** All data models, persistence, and sync
- **Output:** `.claude/reviews/outputs/09-data-engineer-report.md`

## Instructions

Use extended thinking. Review the data layer for correctness, efficiency, and scalability. Focus on model design, relationships, and sync safety.

### Methodology
1. Review data model design
2. Audit relationships and constraints
3. Check query efficiency
4. Review sync strategy (if applicable)
5. Document findings progressively

### Review Order

**Section 1: Model Design**
Review all data models.
Write findings.

**Section 2: Relationships**
Review model relationships.
Write findings.

**Section 3: Queries**
Review data fetching patterns.
Write findings.

**Section 4: Persistence**
Review save/load operations.
Write findings.

**Section 5: Sync (if applicable)**
Review CloudKit/iCloud sync.
Write findings.

## What to Look For

### Model Design (Category: Models)
- [ ] Models are normalized appropriately
- [ ] Correct data types used
- [ ] Optional vs required fields correct
- [ ] Default values sensible
- [ ] Codable conformance where needed
- [ ] Identifiable conformance

### Relationships (Category: Relationships)
- [ ] Relationships properly defined
- [ ] Inverse relationships set
- [ ] Delete rules appropriate (cascade, nullify)
- [ ] No circular strong references
- [ ] Many-to-many handled correctly

### Queries (Category: Queries)
- [ ] Predicates efficient
- [ ] Sorting indexes exist for sorted queries
- [ ] Fetch limits used for large collections
- [ ] Batch fetching where appropriate
- [ ] No N+1 query problems

### Persistence (Category: Persistence)
- [ ] Save operations error-handled
- [ ] Background context for heavy operations
- [ ] Proper merge policies
- [ ] Migration strategy defined
- [ ] Data integrity maintained

### CloudKit Sync (Category: Sync)
- [ ] Sync-safe model design
- [ ] No required relationships to private data
- [ ] Conflict resolution strategy
- [ ] Offline support
- [ ] Quota handling

## Output Format

### Finding Example
```markdown
## Finding DE-001: Missing Inverse Relationship

- **Severity:** Medium
- **Category:** Relationships
- **File:** `Models/Task.swift`
- **Line(s):** 15
- **Description:** Task has project reference but Project doesn't have tasks array
- **Risk:** SwiftData may not maintain referential integrity correctly
- **Recommendation:** Add inverse relationship

### Code Reference
```swift
// Current (missing inverse)
@Model
final class Task {
    var project: Project?
}

// Recommended
@Model
final class Task {
    @Relationship(inverse: \Project.tasks)
    var project: Project?
}

@Model
final class Project {
    @Relationship(deleteRule: .cascade)
    var tasks: [Task]?
}
```
```

## Integration

### Related Commands
- `/swiftdata-review` - SwiftData review
- `/cloudkit-check` - CloudKit sync check

### Related Skills
- `.claude/skills/swiftdata-patterns.md`

## Final Report Structure

```markdown
# Data Engineer Review Report

**Project:** HealthAppTransfer
**Review Date:** [Date]
**Reviewer Role:** Data Engineer

## Executive Summary
[Overall data layer assessment]

## Data Model Diagram
```
[Entity] ──< [Related Entity]
    │
    └──< [Another Entity]
```

## Findings by Category

### Model Design
[Findings]

### Relationships
[Findings]

### Queries
[Findings]

### Persistence
[Findings]

### Sync
[Findings]

## Model Audit
| Model | Fields | Relationships | Issues |
|-------|--------|---------------|--------|

## Migration Considerations
[Future schema changes to plan for]

## Recommendations
[Prioritized data layer improvements]
```
