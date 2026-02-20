# Project Learnings — HealthAppTransfer

> This file accumulates knowledge over time. Claude reads it each session to avoid repeating mistakes and leverage successful patterns.

## Patterns That Work

<!-- Approaches that have proven successful in this project -->

### Code Patterns
<!-- Successful coding patterns discovered -->
- Multi-platform (iOS+macOS) files using `UIDevice` need `#if canImport(UIKit)` guard — macOS target will fail without it.
- macOS-only `#if os(macOS)` views using SwiftData need their own `@Environment(\.modelContext)` — can't rely on the iOS block having it. PairingView's macOS pairButton was missing `modelContext` arg to `completePairing()`.
- `Color(.systemBackground)` doesn't compile on macOS — `NSColor` has no `.systemBackground`. Use `#if canImport(UIKit)` with `Color(.windowBackgroundColor)` fallback for macOS.

### Testing Patterns
<!-- What works for testing in this project -->
- HealthKit queries (`HKSampleQuery`, `HKStatisticsQuery`) are untestable via `execute(_ query:)` — completion handlers are internal. Add async methods to `HealthStoreProtocol` (like `dataExists(for:)`) and mock at that level instead.
- xcodegen's default scheme does NOT include the unit test target. Add an explicit `schemes:` section in `project.yml` with `HealthAppTransferTests` in the test plan.

### Architecture Patterns
<!-- Structural decisions that work well -->
- All core services are Swift actors (HealthKitService, NetworkServer, CertificateService, PairingService, KeychainStore, AuditService) for thread safety.
- To parallelize work inside an actor with TaskGroup, capture `Sendable` dependencies as locals (`let store = self.store`) before the group — child tasks don't inherit actor isolation, so direct property access would re-serialize through the actor.
- Available simulators are iPhone 17 series (17, 17 Pro, 17 Pro Max, Air) — no iPhone 16. Use `iPhone 17 Pro` for xcodebuild commands.
- SwiftData persistence uses `PersistenceConfiguration.makeModelContainer()` factory in `SchemaVersions.swift` — all model types registered in `SchemaV1` with `HealthAppMigrationPlan` for future migrations.

## Mistakes to Avoid

<!-- Things that didn't work - don't repeat these -->

### Failed Approaches
<!-- Approaches that were tried and failed -->
_None documented yet. Use `/learn` to record failures._

### Common Pitfalls
<!-- Gotchas specific to this project -->
- xcodegen overwrites `.entitlements` files to empty `<dict/>` during `generate` — always restore entitlements content after running xcodegen.
- This machine has no iPhone 16 simulator — use `iPhone 17` (or check available destinations) for xcodebuild commands.
- CocoaMQTT pulls two transitive deps: Starscream (WebSocket) and MqttCocoaAsyncSocket (TCP) — these are expected, not extra third-party additions.

### Anti-Patterns Found
<!-- Patterns that cause problems here -->
_None documented yet._

## Codebase Knowledge

<!-- Deep understanding of this specific codebase -->

### Key Abstractions
<!-- Important concepts/classes/modules and how they work -->
_None documented yet._

### Integration Points
<!-- How different parts connect -->
_None documented yet._

### Performance Considerations
<!-- What affects performance in this codebase -->
- HealthKit has NO efficient count-only query API. `HKStatisticsQuery` checks data existence server-side (no memory load) but doesn't return sample counts. `sampleCount()` now returns 0/1 existence — exact counts would require loading all `HKSample` objects into memory.

## External Dependencies

<!-- Knowledge about libraries, APIs, services used -->

### Library Quirks
<!-- Unexpected behaviors in dependencies -->
_None documented yet._

### API Patterns
<!-- How to effectively use external APIs -->
_None documented yet._

## Process Learnings

<!-- What works for development workflow -->

### Effective Workflows
<!-- Sequences of actions that work well -->
_None documented yet._

### Communication Patterns
<!-- How to effectively work with the user -->
_None documented yet._

## Session Insights

<!-- Learnings from specific sessions -->

| Date | Insight | Category | Impact |
|------|---------|----------|--------|
| _None yet_ | - | - | - |

---

## How to Add Learnings

Use the `/learn` command to add new learnings:
- `/learn pattern: [description]` - Record a successful pattern
- `/learn mistake: [description]` - Record something to avoid
- `/learn insight: [description]` - Record codebase knowledge

Or ask Claude: "Record that [X] works well" or "Remember to avoid [Y]"

---
*This file grows over time. The more you use it, the better Claude performs on this project.*
