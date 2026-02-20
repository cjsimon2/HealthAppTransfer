# Performance Engineer Review

## Role Context
- **Perspective:** Performance engineer optimizing app speed
- **Expertise:** iOS performance, profiling, optimization
- **Scope:** All code affecting app performance
- **Output:** `.claude/reviews/outputs/06-performance-engineer-report.md`

## Instructions

Use extended thinking. Review code for performance issues that could affect user experience. Focus on launch time, scrolling, animations, and memory usage.

### Methodology
1. Review app launch sequence
2. Audit view rendering performance
3. Check memory usage patterns
4. Review async operations
5. Document findings progressively

### Review Order

**Section 1: App Launch**
Review app initialization and first screen render.
Write findings.

**Section 2: List/Collection Performance**
Review lists and scrollable content.
Write findings.

**Section 3: Image Handling**
Review image loading and caching.
Write findings.

**Section 4: Memory Management**
Review memory allocation and retention.
Write findings.

**Section 5: Network Operations**
Review network request efficiency.
Write findings.

## What to Look For

### Launch Performance (Category: Launch)
- [ ] Minimal work in app init
- [ ] Lazy loading of non-critical resources
- [ ] No blocking main thread at launch
- [ ] Proper async initialization
- [ ] First frame renders quickly

### View Performance (Category: Views)
- [ ] View bodies are lightweight
- [ ] No expensive computation in body
- [ ] Lazy containers for long lists
- [ ] Proper use of @ViewBuilder
- [ ] Equatable views where beneficial
- [ ] Animation efficiency

### Memory (Category: Memory)
- [ ] No memory leaks
- [ ] Proper image downsampling
- [ ] Cache size limits
- [ ] Autoreleasepool for batches
- [ ] No unnecessary object retention
- [ ] Combine subscription cleanup

### Async Operations (Category: Async)
- [ ] Work on background queues
- [ ] Proper cancellation handling
- [ ] No unnecessary main thread work
- [ ] Batched operations where appropriate
- [ ] Pagination for large data sets

### Data Efficiency (Category: Data)
- [ ] Efficient queries (predicates, limits)
- [ ] Proper indexing
- [ ] Batch fetching
- [ ] Incremental loading
- [ ] Caching strategies

## Output Format

### Finding Example
```markdown
## Finding PE-001: Heavy Computation in View Body

- **Severity:** High
- **Category:** Views
- **File:** `Views/AnalyticsView.swift`
- **Line(s):** 35-50
- **Description:** Statistics calculations performed directly in view body
- **Impact:** View stutters during updates, drops below 60fps
- **Recommendation:** Move calculation to ViewModel, cache results

### Code Reference
```swift
// Current (slow)
var body: some View {
    let stats = items.map { calculate($0) }.reduce(0, +)
    Text("\(stats)")
}

// Recommended (fast)
// In ViewModel:
@Published var stats: Int = 0

func updateStats() {
    Task {
        let result = await calculateStats()
        await MainActor.run { stats = result }
    }
}
```

### Profiling Data
- Frame rate: 45fps during scroll (target: 60fps)
- Main thread time: 25ms per frame (target: <16ms)
```

## Integration

### Related Commands
- `/memory-audit` - Memory leak detection

### Related Skills
- `.claude/skills/swiftui-performance.md`

## Final Report Structure

```markdown
# Performance Engineer Review Report

**Project:** HealthAppTransfer
**Review Date:** [Date]
**Reviewer Role:** Performance Engineer

## Executive Summary
[Overall performance assessment]

## Performance Metrics
| Metric | Current | Target |
|--------|---------|--------|
| Launch Time | | <1s |
| List Scroll | | 60fps |
| Memory Peak | | <100MB |

## Findings by Category

### Launch Performance
[Findings]

### View Performance
[Findings]

### Memory
[Findings]

### Async Operations
[Findings]

### Data Efficiency
[Findings]

## Optimization Opportunities
[Prioritized by impact]

## Profiling Recommendations
[Instruments to use for further analysis]
```
