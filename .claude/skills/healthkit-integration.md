# HealthKit Integration Guidelines

## Always Check Availability First
```swift
guard HKHealthStore.isHealthDataAvailable() else {
    // HealthKit not available (iPad, macOS without Apple Silicon, etc.)
    // Provide graceful degradation — manual entry fallback
    return
}
```

## Request Only Needed Types
- Request the minimum set of `HKObjectType` your feature needs.
- Request read-only access unless you explicitly write data.
- Group related requests together (don't prompt multiple times).

```swift
let readTypes: Set<HKObjectType> = [
    HKQuantityType(.stepCount),
    HKQuantityType(.heartRate),
    HKCategoryType(.sleepAnalysis)
]

try await healthStore.requestAuthorization(toShare: Set(), read: readTypes)
```

## Handle Denied Authorization Gracefully
- **Never** tell the user their authorization was denied — HealthKit returns `.notDetermined` for denied types (privacy by design).
- If no data is returned, show an empty state with an option to check Health settings.

```swift
// GOOD — graceful empty state
if heartRateData.isEmpty {
    Text("No heart rate data available")
    Text("You can check Health app settings to enable access")
}

// BAD — assuming denial
if heartRateData.isEmpty {
    Text("You denied heart rate access") // WRONG — privacy violation
}
```

## Use HKStatisticsQuery for Aggregates
- For daily step counts, average heart rate, or sleep totals, use `HKStatisticsQuery`.
- For time-series data (heart rate over a day), use `HKSampleQuery` with date predicates.
- For real-time observation, use `HKObserverQuery` (bridged via Combine).

## Background Delivery
- `enableBackgroundDelivery()` is iOS-only (not macOS).
- Requires `com.apple.developer.healthkit.background-delivery` entitlement.
- Register in `BGTaskScheduler` for periodic sync.

## Mac Catalyst Gotchas
- Mac Catalyst does NOT inherit HealthKit authorization from iPhone.
- `#if os(iOS)` is TRUE on Mac Catalyst — use `#if targetEnvironment(macCatalyst)` to distinguish.
- HealthKit is available on macOS via Catalyst but has limited data (no sensors).

## Data Privacy — Never Transmit Externally
- HealthKit data must NEVER leave the device or be sent to external servers.
- Store HealthKit-derived insights locally only.
- If showing HealthKit data in a shareable view, exclude health data from the share.
- This is both an App Store requirement and an ethical obligation.

## HealthDataType Mapping
- All 180+ health data types are mapped in `HealthDataType.swift`.
- Use `HealthDataType` enum as the single source of truth for type identifiers, display names, categories, and units.
- Filter by `isQuantityType` before using `AggregationEngine`.
- HealthKit disallows **read** authorization for `HKCorrelationType` — use constituent types instead.
