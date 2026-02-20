The edit was blocked by permissions. The key project-specific insights from this discovery session are:

1. **`HealthDataType` is the cross-cutting bottleneck** — every service, mapper, and view depends on it. Expanding from 34→150+ touches every layer.
2. **`availableTypes()` queries sequentially** — at 150+ types, needs `TaskGroup` parallelization.
3. **`sampleCount()` fetches ALL samples just to count** — should use `HKStatisticsQuery` instead.
4. **Entitlements already include background-delivery + CloudKit** — code just needs to be written.
5. **All services created in `ContentView.init()`** — no DI container, so adding services means touching ContentView.

These should be added to LEARNINGS.md when permissions allow.