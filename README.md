# HealthAppTransfer

An iOS/macOS app for exporting, syncing, and automating Apple Health data. Built with SwiftUI, HealthKit, CloudKit, and SwiftData.

## Features

- **180+ Health Data Types** — Reads from every HealthKit category: activity, heart, vitals, body measurements, nutrition, sleep, workouts, symptoms, and more.
- **Multi-Format Export** — Export health data as JSON (flat or grouped), CSV, or GPX (with workout routes and heart rate).
- **Device-to-Device Transfer** — TLS-secured local network server with QR code pairing and bearer token auth.
- **CloudKit Sync** — Delta sync via CKServerChangeToken between iOS and macOS using iCloud private database.
- **Background Sync** — BGTaskScheduler + HKObserverQuery for automatic hourly sync with Live Activity progress on Dynamic Island and Lock Screen.
- **Home Screen Widgets** — WidgetKit widgets (small, medium, large) showing configurable health metrics with sparkline charts, powered by live HealthKit queries with cached fallback.
- **Automations** — Configurable triggers (on-change or interval) that push health data to REST APIs, MQTT brokers, Home Assistant, cloud storage, or Calendar events.
- **Siri Shortcuts** — App Intents for "Get latest value", "Sync now", and "Export health data".
- **Biometric Lock** — Optional Face ID / Touch ID gate on app launch.
- **Bonjour Discovery** — Automatic LAN discovery via `_healthsync._tcp` so Mac clients find the iOS server.
- **Mac Catalyst** — Runs natively on macOS via Mac Catalyst with NavigationSplitView sidebar, macOS menu commands (Cmd+Shift+R sync, Cmd+E export), and SwiftData fallback for health data (since HealthKit is unavailable on Mac).

## Requirements

- Xcode 15+
- iOS 17.0+ / macOS 14.0+ (Mac Catalyst)
- Swift 5.9+
- Apple Developer account (for HealthKit entitlement)

## Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/cjsimon2/HealthAppTransfer.git
   cd HealthAppTransfer
   ```

2. **Open in Xcode**
   ```bash
   open HealthAppTransfer.xcodeproj
   ```

3. **Configure signing** — Select your development team under Signing & Capabilities.

4. **Build and run** — `Cmd+R` to launch on a simulator or device.

> HealthKit is not available in the iOS Simulator. To test with real data, run on a physical device.

## Architecture

MVVM with Combine, using Swift actors for thread-safe service layer.

```
HealthAppTransfer/                  # Main app target (99 Swift files)
├── App/                            # App entry point, entitlements, Info.plist
├── Views/                          # SwiftUI views (MVVM)
│   ├── Dashboard/                  # Health metrics dashboard with metric cards
│   ├── HealthData/                 # Browse & detail views for all types
│   ├── Export/                     # Quick export UI
│   ├── Automations/                # REST, MQTT, Calendar, Cloud, Home Assistant forms
│   ├── Settings/                   # Pairing, LAN sync, security, sync config
│   ├── Onboarding/                 # Welcome, HealthKit, notification, quick-setup steps
│   └── Charts/                     # Swift Charts + MapKit workout route view
├── ViewModels/                     # @MainActor ObservableObject view models (10 files)
├── Models/                         # HealthDataType (180+ types), HealthSampleDTO, DTOs
│   └── Persistence/                # SwiftData @Model classes (8 models)
├── Services/
│   ├── HealthKit/                  # HealthKitService (actor), BackgroundSyncService, AggregationEngine
│   ├── Export/                     # ExportService (actor), JSON v1/v2, CSV, GPX formatters
│   ├── Network/                    # NetworkServer (TLS HTTP), BonjourDiscovery, LANSyncClient
│   ├── Security/                   # PairingService, CertificateService, KeychainStore, BiometricService
│   ├── Sync/                       # CloudKitSyncService, CloudKitRecordMapper
│   ├── Automations/                # AutomationScheduler, AutomationExecutor, 5 automation types
│   ├── Audit/                      # AuditService for security event logging
│   └── Widget/                     # WidgetDataStore for sharing data with widgets
├── Intents/                        # App Intents for Siri Shortcuts (5 files)
├── Extensions/                     # DER encoder, loggers, network helpers, QR renderer, ShareSheet
├── Theme/                          # AppColors, AppTypography, AppLayout, ChartColors, ViewModifiers
└── Resources/                      # Assets catalog, localization

HealthAppTransferWidget/            # Widget extension (5 Swift files)
├── HealthAppTransferWidgetBundle   # Widget bundle entry point
├── HealthMetricWidget              # Configurable health metric widget (small/medium/large)
├── HealthMetricProvider            # AppIntentTimelineProvider with HealthKit queries
├── HealthWidgetViews               # Widget views: small, medium, large + sparkline
└── SyncLiveActivity                # Live Activity for background sync progress

HealthAppTransferTests/             # Unit tests (44 files, 550 tests)
HealthAppTransferUITests/           # UI tests (1 file, 9 tests)
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Swift actors for services | Thread-safe access to HealthKit, network, and pairing state without manual locking |
| ServiceContainer (struct) | Single dependency container created at launch, injected into view hierarchy; memberwise init for test injection |
| SwiftData for persistence | Schema versioning via `HealthAppMigrationPlan`, iCloud sync, `@Model` for 8 persistent types |
| ExportFormatter protocol | Strategy pattern for JSON v1, JSON v2, CSV, and GPX output — easy to add new formats |
| HealthDataType enum (180+ cases) | Single source of truth mapping app types to HKQuantityTypeIdentifier, display names, categories |
| Runtime HealthKit checks | `HealthKitService.isAvailable` instead of `#if os(macOS)` — needed because Mac Catalyst compiles as `os(iOS)` |
| WidgetDataStore (App Groups) | Shared UserDefaults suite for passing health metric snapshots between main app and widget extension |

## Network API

The iOS app runs a TLS HTTP server for device-to-device transfer. Endpoints:

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/status` | None | Server info and available type count |
| `POST` | `/api/v1/pair` | None | Exchange pairing code for bearer token |
| `GET` | `/health/types` | Bearer | List available health data types |
| `GET` | `/health/data?type=stepCount&offset=0&limit=500` | Bearer | Paginated health samples |

### Pairing Flow

1. iOS app generates a 6-digit code (valid 5 minutes) and displays it / encodes as QR
2. Mac client sends `POST /api/v1/pair` with the code
3. Server returns a bearer token (32-byte random, base64url)
4. All subsequent requests use `Authorization: Bearer <token>`

## Export Formats

| Format | Extension | Description |
|--------|-----------|-------------|
| JSON (Flat) | `.json` | Array of `HealthSampleDTO` objects |
| JSON (Grouped) | `.json` | Samples grouped by type with device metadata |
| CSV | `.csv` | Flat table with one row per sample |
| GPX | `.gpx` | Workout routes with GPS tracks, elevation, and heart rate in `<extensions>` |

## Automations

Automations execute on health data changes (HKObserverQuery) or timed intervals:

| Type | Destination | Protocol |
|------|-------------|----------|
| REST | Any HTTP endpoint | POST with JSON body |
| MQTT | MQTT 3.1.1 / 5.0 broker | Publish to configurable topic |
| Home Assistant | HA instance | REST API with long-lived access token |
| Cloud Storage | iCloud Drive / Files | Export file to cloud provider |
| Calendar | Apple Calendar | Create workout events with details |

## Widgets

The app includes a WidgetKit extension with two widget types:

### Health Metric Widget

Configurable widget showing health metrics with sparkline trends. Uses `AppIntentConfiguration` for user-selectable metrics.

| Size | Metrics Shown | Layout |
|------|--------------|--------|
| Small | 1 | Single metric with sparkline and value |
| Medium | Up to 3 | Horizontal layout with dividers |
| Large | Up to 6 | 2-column grid with header |

Data pipeline: HealthKit live query (today's stats) → cached `WidgetMetricSnapshot` fallback → placeholder data. Refreshes every 15 minutes.

### Sync Live Activity

Shows background sync progress on Dynamic Island and Lock Screen via `ActivityKit`:
- Compact: sync icon + percentage
- Expanded: progress bar, current type name, sample count
- Lock Screen: full progress view with status badge

## Privacy & Security

- **Read-only HealthKit access** — The app never writes to HealthKit
- **TLS encryption** — All network transfers use self-signed TLS certificates stored in Keychain
- **Bearer token auth** — Time-limited pairing codes, single-use consumption
- **Biometric lock** — Optional Face ID / Touch ID gate with automatic lock on background
- **Audit logging** — All API access events are recorded
- **No analytics or tracking** — No data leaves the device except through user-initiated export/sync
- **ITSAppUsesNonExemptEncryption: NO** — Uses only Apple-provided encryption (TLS, Keychain)

## Testing

```bash
# Run unit tests (550 tests)
xcodebuild test -project HealthAppTransfer.xcodeproj -scheme HealthAppTransfer -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Run UI tests (9 tests)
xcodebuild test -project HealthAppTransfer.xcodeproj -scheme HealthAppTransfer -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:HealthAppTransferUITests
```

| Metric | Value |
|--------|-------|
| Unit tests | 550 across 44 test files |
| UI tests | 9 covering onboarding, navigation, export, settings, dashboard |
| File coverage | ~90% |
| Simulator | iPhone 17 Pro (no iPhone 16 simulators available) |

- HealthKit queries are tested via `HealthStoreProtocol` — mocks return `[AggregatedSample]` to bypass untestable HK types
- UI tests use `-UITestingSkipOnboarding` launch argument to bypass the onboarding flow
- SwiftUI `Picker` in `Form` renders as a `Button` in XCUI — use `app.buttons["identifier"]` to find them

## License

Private repository. All rights reserved.
