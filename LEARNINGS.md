# Project Learnings — HealthAppTransfer

> This file accumulates knowledge over time. Claude reads it each session to avoid repeating mistakes and leverage successful patterns.

## Patterns That Work

<!-- Approaches that have proven successful in this project -->

### Code Patterns
<!-- Successful coding patterns discovered -->
- Multi-platform (iOS+macOS) files using `UIDevice` need `#if canImport(UIKit)` guard — macOS target will fail without it.
- macOS-only `#if os(macOS)` views using SwiftData need their own `@Environment(\.modelContext)` — can't rely on the iOS block having it. PairingView's macOS pairButton was missing `modelContext` arg to `completePairing()`.
- `Color(.systemBackground)` doesn't compile on macOS — `NSColor` has no `.systemBackground`. Use `#if canImport(UIKit)` with `Color(.windowBackgroundColor)` fallback for macOS.
- Dashboard metric cards must filter to `isQuantityType` before loading — `AggregationEngine.aggregate()` throws `unsupportedType` for category/correlation/characteristic/workout types, and Charts needs numeric data.

### Testing Patterns
<!-- What works for testing in this project -->
- HealthKit queries (`HKSampleQuery`, `HKStatisticsQuery`) are untestable via `execute(_ query:)` — completion handlers are internal. Add async methods to `HealthStoreProtocol` (like `dataExists(for:)`) and mock at that level instead.
- `HKStatisticsCollection` and `HKStatistics` can't be constructed in tests — for `HKStatisticsCollectionQuery`, return `[AggregatedSample]` from the protocol method so mocks bypass HK types entirely.
- Cumulative quantity types (stepCount, energy) only support `.cumulativeSum`; discrete types (heartRate, bodyMass) only support `.discreteAverage/.discreteMin/.discreteMax`. Mixing causes HK errors — validate aggregation style before building `HKStatisticsOptions`.
- xcodegen's default scheme does NOT include the unit test target. Add an explicit `schemes:` section in `project.yml` with `HealthAppTransferTests` in the test plan.
- `HKCategorySample` for `menstrualFlow` requires `HKMetadataKeyMenstrualCycleStart` metadata at creation — tests crash with `_HKObjectValidationFailureException` without it.
- `HKCorrelation` requires at least one `HKSample` object — can't create empty correlations in tests; HealthKit throws `_HKObjectValidationFailureException`.

### Architecture Patterns
<!-- Structural decisions that work well -->
- HealthDataType uses static dictionaries (not giant switches) for identifier/displayName/unit lookups — keeps the 182-case enum maintainable. `kind` is derived from which identifier dictionary contains the type.
- HKCharacteristicType has no HKSampleType — guard with `isSampleBased` before calling `sampleType`, `dataExists(for:)`, or sample queries. Use `objectType` (HKObjectType) for authorization which covers all type kinds.
- All core services are Swift actors (HealthKitService, NetworkServer, CertificateService, PairingService, KeychainStore, AuditService) for thread safety.
- SwiftData `@Model` classes aren't `Sendable` — when passing config to another actor, snapshot into a `Sendable` struct on the main actor first (see `RESTPushParameters` in `RESTAutomation.swift`).
- To parallelize work inside an actor with TaskGroup, capture `Sendable` dependencies as locals (`let store = self.store`) before the group — child tasks don't inherit actor isolation, so direct property access would re-serialize through the actor.
- Available simulators are iPhone 17 series (17, 17 Pro, 17 Pro Max, Air) — no iPhone 16. Use `iPhone 17 Pro` for xcodebuild commands.
- SwiftData persistence uses `PersistenceConfiguration.makeModelContainer()` factory in `SchemaVersions.swift` — all model types registered in `SchemaV1` with `HealthAppMigrationPlan` for future migrations.
- `enableBackgroundDelivery(for:frequency:)` is iOS-only (not macOS) — needs `#if os(iOS)` guard, separate from `#if canImport(UIKit)` used for BGTask code. `HKObserverQuery` works on macOS but only fires while app is running.
- `#if canImport(ActivityKit)` is true on macOS (module exists in SDK) but ActivityKit APIs (`Activity`, `ActivityAuthorizationInfo`) are unavailable at runtime — use `#if os(iOS) && canImport(ActivityKit)` instead.
- Widget extension (HealthAppTransferWidget.appex) is iOS-only — macOS Catalyst builds fail with "embedded content built for iOS platform" unless `platformFilters = (ios, )` is added to both the embed build file and target dependency in project.pbxproj.
- BGTaskScheduler.shared.register() must be called before app finishes launching — in SwiftUI, call it in the App struct's `init()` after creating the service.
- `HealthDataType.groupedByCategory` is the canonical way to get types grouped by `HealthDataCategory` in display order — use it in views/VMs instead of manually filtering `allCases`.
- XcodeGen `generate` now works again — previously broken in v2.44.1. Run `xcodegen generate` after adding new files; the `sources: - path: HealthAppTransfer` glob picks them up automatically.
- `AggregatedSample` chart value extraction: use `sample.sum ?? sample.average ?? sample.latest ?? 0` — cumulative types populate `sum`, discrete types populate `average`. Request both `[.sum, .average]` operations and AggregationEngine silently skips incompatible ones.
- XcodeGen overwrites `.entitlements` files during `generate` — must use `entitlements.properties` in `project.yml` instead of manually editing the plist file, or changes get wiped on next generate.
- To avoid threading a ViewModel through ContentView → MainTabView → SettingsView, a leaf view can own its VM via `@StateObject` with init-time injection: `_viewModel = StateObject(wrappedValue: VM(dep: dep))`. Just pass the lightweight dependency (e.g. `HealthKitService`) instead of the full VM.
- Storing small collections (sync history) as JSON-encoded `Data?` in a SwiftData `@Model` is pragmatic when entries don't need individual queryability — avoids a separate model class and relationship overhead.
- App Intents (`AppIntent.perform()`) can't use the app's `ServiceContainer` — the system creates intents independently. Create fresh `HealthKitService`/`BackgroundSyncService` instances inside `perform()` since they're lightweight actor wrappers. Use `PersistenceConfiguration.makeModelContainer()` for SwiftData access.
- `MQTTAutomation.swift` previously had actor isolation and Sendable warnings — fixed with `@unchecked Sendable` class + `@preconcurrency import CocoaMQTT`.
- `HKWorkoutRouteQuery` delivers `CLLocation` arrays in batches (not all at once) — accumulate in a local array and only resolve the continuation when the `done` flag is `true`. Resuming the continuation on each batch will crash.
- CloudKit `CKDatabase.modifyRecords(saving:deleting:savePolicy:atomicZone:)` has a 400-record limit per operation — batch uploads accordingly.
- `CKServerChangeToken` must be archived via `NSKeyedArchiver` to persist as `Data` in SwiftData — `CKServerChangeToken` conforms to `NSSecureCoding`.
- macOS `NSSharingServicePicker` must be wrapped in `NSViewRepresentable` with a Coordinator to work in SwiftUI — needs a real `NSButton` as anchor; can't show it from a plain SwiftUI `Button` action without an `NSView` reference.
- GPXFormatter doesn't conform to `ExportFormatter` protocol — GPX needs `[GPXTrack]` (location data from HKWorkoutRoute) not `[HealthSampleDTO]`. Keep its `format(tracks:)` signature separate.
- Swift type-checker chokes on large array literals (16+ elements) built inline — break into sequential `.append()` calls to avoid "unable to type-check this expression in reasonable time".
- Automation secrets (tokens, passwords) that shouldn't live in SwiftData: store in Keychain keyed by `persistentModelID.hashValue.description`. Must call `modelContext.insert()` + `save()` before reading `persistentModelID` on new objects — it's unset until persisted.
- For view→actor reload signals, use `NotificationCenter.default.notifications(named:)` async stream inside the actor — cleaner than Combine or delegate patterns, and the `for await` loop naturally respects actor isolation. See `AutomationScheduler.observeConfigChanges()`.

## Mistakes to Avoid

<!-- Things that didn't work - don't repeat these -->

### Failed Approaches
<!-- Approaches that were tried and failed -->
_None documented yet. Use `/learn` to record failures._

### Common Pitfalls
<!-- Gotchas specific to this project -->
- Claude Code hooks are loaded into memory at session start — deleting hook script files mid-session causes every subsequent tool call and stop event to error with "No such file or directory". Always remove the settings reference first, then start a new session before deleting the script files.
- xcodegen overwrites `.entitlements` files to empty `<dict/>` during `generate` — always restore entitlements content after running xcodegen.
- Both app and widget Info.plist had hardcoded `CFBundleShortVersionString = 1.0` instead of `$(MARKETING_VERSION)` — causes version mismatch warning. Also app Info.plist was missing `UISupportedInterfaceOrientations` and `UILaunchScreen` keys (required unless app declares full-screen-only).
- This machine has no iPhone 16 simulator — use `iPhone 17` (or check available destinations) for xcodebuild commands.
- CocoaMQTT pulls two transitive deps: Starscream (WebSocket) and MqttCocoaAsyncSocket (TCP) — these are expected, not extra third-party additions.
- `UIDevice.current` properties are main-actor-isolated in Swift 6 — `nonisolated` functions in an actor can't access them. Use `await MainActor.run { ... }` instead.
- `MQTTAutomation` must be `@unchecked Sendable` (not an actor) because `CocoaMQTTDelegate` requires `NSObject`. Use `@preconcurrency import CocoaMQTT` to suppress third-party Sendable warnings.
- `CKContainer.default()` crashes at init time without CloudKit entitlements — defer CKContainer creation to first use, not in `init()`. See `CloudKitSyncService.swift`.
- macOS Mac Catalyst builds with CloudKit/HealthKit entitlements can't be run from CLI (`xcodebuild` + `open`) — `CODE_SIGNING_ALLOWED=NO` strips entitlements and `CKContainer.default()` crashes with nil containerIdentifier. Must build/run from Xcode GUI with automatic signing ("My Mac" destination).
- SwiftData `ModelConfiguration` defaults to CloudKit integration, which rejects `@Attribute(.unique)` — add `cloudKitDatabase: .none` when managing CloudKit manually. See `SchemaVersions.swift`.
- WidgetKit extensions require `NSExtension` with `NSExtensionPointIdentifier: com.apple.widgetkit-extension` in Info.plist — Simulator refuses to install without it.
- `BGTaskScheduler.shared.register()` requires matching `BGTaskSchedulerPermittedIdentifiers` in Info.plist — crashes without them. Also needs `fetch` in `UIBackgroundModes` for `BGAppRefreshTask`.
- `URLSession` moves `httpBody` to `httpBodyStream` before sending — `URLProtocol` subclass mocks must read from `httpBodyStream` to capture request bodies.
- HealthKit disallows requesting **read** authorization for `HKCorrelationType` (`bloodPressure`, `food`) — crashes with `NSInvalidArgumentException`. Must authorize their component quantity types instead (e.g. `bloodPressureSystolic`/`Diastolic`, dietary types). Exclude correlation types from `allObjectTypes` used in `requestAuthorization()`.
- `HKQuantityTypeIdentifier.physicalEffort` uses `kcal/hr·kg` (Apple effort score / METs), NOT `.count()`. Calling `doubleValue(for: .count())` on a physicalEffort sample crashes with `NSInvalidArgumentException: Attempt to convert incompatible units`. This only manifests on real devices (Simulator has no physicalEffort data). Always verify `HealthSampleMapper.unitMap` entries against real device data — the assertionFailure fallback to `.count()` in `preferredUnit(for:)` silently produces crashes in release builds.
- Mac Catalyst does NOT inherit HealthKit authorization from iPhone — each platform requires its own `requestAuthorization()` call. Any code path that fetches HealthKit data (sync, export, intents) must ensure authorization first, not assume onboarding already handled it. `requestAuthorization()` is a no-op if already granted, so calling it defensively is safe.
- `#if os(iOS)` is TRUE on Mac Catalyst — platform-conditional views using `#if os(iOS)` / `#if os(macOS)` will show the iOS variant on Catalyst, not the macOS one. Use `#if targetEnvironment(macCatalyst)` BEFORE `#if os(iOS)` to distinguish iPhone from Mac Catalyst. The `#if os(macOS)` block is dead code on Catalyst. Similarly, `NSPasteboard` is unavailable on Catalyst — use `UIPasteboard.general.string` instead.

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
