# Project State — HealthAppTransfer

> This file is automatically maintained. Claude reads it at session start and updates it during work.

## Current Phase

**Phase:** Active Development
**Status:** In Progress
**Last Updated:** 2026-02-24

## Active Tasks

<!-- Tasks currently being worked on -->
| Task | Status | Progress | Blocker |
|------|--------|----------|---------|
| _None_ | - | - | - |

## Completed Tasks

<!-- Recently completed work (last 15, deduplicated) -->
| Task | Completed | Files Changed |
|------|-----------|---------------|
| ✅ feat: add Insights tab with pattern detection and correlation analysis | 2026-02-24 | 5 new + 1 modified Swift files, project.pbxproj |
| ✅ docs: comprehensive documentation sweep (README, STATE, LEARNINGS) | 2026-02-23 | README.md, STATE.md, LEARNINGS.md |
| ✅ fix: correct 4 UI test assertion mismatches and timing brittleness | 2026-02-22 | HealthAppTransferUITests.swift, LEARNINGS.md |
| ✅ docs: update LEARNINGS.md with Catalyst #if os(macOS) gotcha | 2026-02-22 | LEARNINGS.md |
| ✅ fix: use runtime HealthKit checks instead of compile-time #if os(macOS) for Catalyst | 2026-02-22 | 6 ViewModels, SyncedHealthSample.swift |
| ✅ fix: resolve 13 bugs across sync, Catalyst, TLS, auth, and crash safety | 2026-02-22 | 16 files |
| ✅ fix: Mac Catalyst pairing and sync issues | 2026-02-22 | See commit |
| ✅ fix: use correct unit for physicalEffort in HealthSampleMapper | 2026-02-22 | HealthSampleMapper.swift |
| ✅ style: Wes Anderson UI overhaul with warm theme system | 2026-02-22 | Theme/, 10 view files |
| ✅ docs: add comprehensive README | 2026-02-22 | README.md, STATE.md |
| ✅ fix: App Store audit — entitlements, Info.plist, fatalErrors, version | 2026-02-22 | 6 files |
| ✅ fix: harden GPX export — double-resume guard, altitude filter, HR rounding | 2026-02-22 | HealthKitService, ExportService, GPXFormatter |
| ✅ feat: add heart rate data to GPX export | 2026-02-22 | ExportService.swift, GPXFormatter.swift |
| ✅ style: UI/UX polish across 10 view files | 2026-02-21 | 10 view files |
| ✅ test: add 34 test files to increase coverage from 14% to ~90% | 2026-02-21 | 44 test files |
| ✅ fix: enable macOS Catalyst build and resolve Info.plist warnings | 2026-02-21 | project.pbxproj, Info.plist, entitlements |

## Key Decisions

<!-- Important decisions made during development -->
| Decision | Rationale | Date | Reversible |
|----------|-----------|------|------------|
| Swift actors for all services | Thread-safe HealthKit/Network/Pairing without manual locking | 2026-02-21 | No |
| ServiceContainer struct (not class) | Value-type DI container, memberwise init for test injection | 2026-02-21 | Yes |
| SwiftData over Core Data | Better SwiftUI integration, schema versioning, iCloud sync | 2026-02-21 | No |
| ExportFormatter protocol | Strategy pattern for multiple export formats (JSON/CSV/GPX) | 2026-02-21 | Yes |
| HealthDataType single enum (180+ cases) | Single source of truth for all HK type mapping, display names, categories | 2026-02-21 | No |
| Bearer token auth for LAN API | Simple, stateless auth; tokens persisted in Keychain | 2026-02-21 | Yes |

## Current Blockers

<!-- Issues preventing progress -->
- _None_

## Session History

<!-- Last 5 sessions summary -->
| Date | Work Done | Key Outcomes |
|------|-----------|--------------|
| 2026-02-24 | Insights tab feature | New Insights tab with weekly summaries, personal records, day-of-week patterns, anomaly detection, and cross-metric correlation scatter plots. 5 new files + 13 tests |
| 2026-02-23 | Documentation sweep (`/document ALL`) | README updated (widgets, Catalyst, corrected metrics), STATE.md cleaned up (deduped tasks, accurate counts), LEARNINGS.md filled in (key abstractions, integration points, library quirks) |
| 2026-02-22 | Catalyst data fix, 13-bug deep debug, UI test fixes | Runtime HealthKit checks replaced compile-time `#if os(macOS)`, TLS/auth/sync hardening, UI test timing fixes |
| 2026-02-22 | UI theme, App Store audit, GPX improvements | Wes Anderson warm theme, entitlements/Info.plist fixes, HR data in GPX, app icon |
| 2026-02-21 | Test coverage, Catalyst build, UI polish | 550 tests across 44 files (~90% coverage), macOS Catalyst support, accessibility labels, 9 UI tests |
| 2026-02-21 | Initial project build fixes | Concurrency warnings, CloudKit entitlement, widget config, Info.plist |

## Codebase Insights

### Patterns Found
- All services are Swift actors (HealthKitService, ExportService, NetworkServer, PairingService, etc.)
- ViewModels are `@MainActor` ObservableObjects created via ServiceContainer factory methods
- HealthDataType enum is the central mapping layer — all HealthKit identifiers, display names, categories derive from it
- Export uses strategy pattern: `ExportFormatter` protocol with JSON v1/v2, CSV, GPX concrete formatters
- Background sync chain: BGTask -> performSync() -> CloudKit sync -> execute automations
- Automations use HKObserverQuery (on-change) and Task.sleep timers (interval) as triggers

### Gotchas & Warnings
- HealthKit not available in iOS Simulator — must test on device for real data
- HKWorkoutRouteQuery handler fires multiple times (batch delivery) — need `resumed` guard
- GPX altitude requires `verticalAccuracy >= 0` check; negative means unreliable
- CloudKit zone must be created before any upload/download; idempotent create on each sync
- UI tests use `-UITestingSkipOnboarding` launch argument to bypass onboarding flow

### Important Files
| File | Purpose | Notes |
|------|---------|-------|
| `README.md` | Project documentation | Comprehensive feature/API/architecture docs |
| `CLAUDE.md` | Project guidance | Read at session start |
| `STATE.md` | This file | Auto-updated |
| `ServiceContainer.swift` | DI container | All services + ViewModel factories |
| `HealthDataType.swift` | 180+ type enum | Maps to HK identifiers, display names, categories |
| `HealthKitService.swift` | Core HealthKit actor | Fetch samples, routes, heart rate, available types |
| `ExportService.swift` | Export pipeline actor | Fetch -> format -> write temp file (+ GPX with HR) |
| `NetworkServer.swift` | TLS HTTP server actor | /status, /pair, /health/types, /health/data |
| `BackgroundSyncService.swift` | BGTask + observer queries | Orchestrates sync + CloudKit + automations + Live Activity |
| `AutomationScheduler.swift` | Automation trigger engine | HKObserverQuery + interval timers |
| `PairingService.swift` | Token management actor | Code generation, validation, device-token mapping, Keychain persistence |
| `ContentView.swift` | Root view | Onboarding gate, biometric lock, HealthKit auth flow |
| `SchemaVersions.swift` | SwiftData setup | Model container factory, migration plan, store recovery |
| `WidgetDataStore.swift` | Widget data bridge | App Groups shared UserDefaults for widget metric snapshots |

## Metrics

<!-- Project health indicators -->
- **Source Files:** 103 app + 5 widget + 46 test = 154 Swift files
- **Source Directories:** 21 (11 app, 1 widget extension, 2 test targets)
- **Health Data Types:** 180+ (quantity, category, correlation, characteristic, workout)
- **Tests:** 563 unit tests, 9 UI tests (45 test files + 1 UI test file)
- **Test Coverage:** ~90% file coverage
- **SwiftData Models:** 8 (SyncConfiguration, PairedDevice, ExportRecord, AuditEventRecord, AutomationConfiguration, UserPreferences, SyncedHealthSample, SchemaVersions)
- **ViewModels:** 11 (Dashboard, HealthData, HealthDataDetail, Chart, Export, Insights, Pairing, LANSync, SecuritySettings, SyncSettings, Onboarding)
- **Build:** Passing (iOS + macOS Catalyst, 0 errors)
- **App Store Readiness:** HealthKit entitlement, camera description, encryption declaration, device capabilities — all added
- **Accessibility:** ~90%+ (labels/identifiers on all interactive elements)
- **Export Formats:** 4 (JSON flat, JSON grouped, CSV, GPX with heart rate)
- **Automation Types:** 5 (REST, MQTT, Home Assistant, Cloud Storage, Calendar)
- **Widget Sizes:** 3 (small, medium, large) + Live Activity
- **Siri Shortcuts:** 3 (Get value, Sync, Export)
- **API Endpoints:** 4 (/status, /api/v1/pair, /health/types, /health/data)
- **Last Successful Build:** 2026-02-24

---
*This file is updated automatically by Claude. Manual edits are preserved.*
