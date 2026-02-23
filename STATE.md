# Project State — HealthAppTransfer

> This file is automatically maintained. Claude reads it at session start and updates it during work.

## Current Phase

**Phase:** Active Development
**Status:** In Progress
**Last Updated:** 2026-02-23

## Active Tasks

<!-- Tasks currently being worked on -->
| Task | Status | Progress | Blocker |
|------|--------|----------|---------|
| _None_ | - | - | - |

## Completed Tasks

<!-- Recently completed work (last 10) -->
| Task | Completed | Files Changed |
|------|-----------|---------------|
| ✅ fix: UI test assertion mismatches and timing brittleness (4 tests) | 2026-02-23 | HealthAppTransferUITests.swift, LEARNINGS.md |
| ✅ docs: update LEARNINGS.md with Catalyst #if os(macOS) gotcha and refresh handoff | 2026-02-22 | See commit |
| ✅ fix: use runtime HealthKit checks instead of compile-time #if os(macOS) for Catalyst | 2026-02-22 | See commit |
| ✅ fix: resolve 13 bugs across sync, Catalyst, TLS, auth, and crash safety | 2026-02-22 | See commit |
| ✅ fix: deep debug — 13 bugs across entitlements, sync, Catalyst, TLS, auth | 2026-02-22 | 16 files (see diff) |
| ✅ fix: Mac Catalyst pairing and sync issues | 2026-02-22 | See commit |
| ✅ fix: use correct unit for physicalEffort in HealthSampleMapper | 2026-02-22 | See commit |
| ✅ art: update app icon to phone-to-laptop transfer design | 2026-02-22 | See commit |
| ✅ docs: update LEARNINGS.md and STATE.md with latest session notes | 2026-02-22 | See commit |
| ✅ chore: delete unreferenced project hooks, simplify safety-check | 2026-02-22 | See commit |
| ✅ fix: remove duplicate hooks from project settings | 2026-02-22 | See commit |
| ✅ style: Wes Anderson UI overhaul with warm theme system | 2026-02-22 | See commit |
| ✅ docs: fix simulator name in README, update handoff.md | 2026-02-22 | See commit |
| ✅ chore: update STATE.md with latest completed task | 2026-02-22 | See commit |
| ✅ docs: add comprehensive README and update STATE.md | 2026-02-22 | See commit |
| ✅ fix: resolve App Store audit findings | 2026-02-22 | See commit |
| ✅ fix: harden GPX export — double-resume guard, altitude filter, HR rounding | 2026-02-22 | See commit |
| ✅ fix: make UI tests reliable with launch argument to bypass onboarding | 2026-02-22 | See commit |
| ✅ chore: replace app icon with new illustrated design | 2026-02-22 | See commit |
| ✅ fix: App Store audit — entitlements, Info.plist, fatalErrors, version | 2026-02-22 | Entitlements, Info.plist, HealthDataType, ExportService, HealthSampleMapper, SettingsView |
| ✅ fix: GPX export — double-resume guard, altitude filter, HR rounding | 2026-02-22 | HealthKitService, ExportService, GPXFormatter, GPXFormatterTests |
| ✅ fix: UI tests — launch argument to bypass onboarding | 2026-02-22 | ContentView, HealthAppTransferUITests |
| ✅ chore: simplify gitignore for xcuserdata and .claudify | 2026-02-22 | See commit |
| ✅ chore: use absolute paths for hook commands in settings | 2026-02-22 | See commit |
| ✅ fix: wait for main content after skipping onboarding in UI tests | 2026-02-22 | See commit |
| ✅ chore: add app icon and simplify asset catalog | 2026-02-22 | See commit |
| ✅ feat: add heart rate data to GPX export | 2026-02-22 | See commit |
| ✅ style: UI/UX polish across 10 view files | 2026-02-21 | MetricCardView, DashboardView, SettingsView, HealthDataDetailView, HealthDataView, QuickExportView, AutomationsView, OnboardingView, ContentView, HealthAppTransferApp |
| ✅ feat: wire up GPX export with workout route fetching | 2026-02-21 | ExportService.swift, HealthKitService.swift |
| ✅ test: add 9 meaningful UI tests replacing placeholder | 2026-02-21 | HealthAppTransferUITests.swift |
| ✅ feat: add accessibility labels/identifiers to 8 views | 2026-02-21 | MQTT/Cloud/Calendar/HA forms, Security/LAN/Paired/QR views |
| ✅ fix: resolve build warnings in test files and update STATE.md metrics | 2026-02-21 | See commit |
| ✅ fix: resolve build warnings in test files | 2026-02-21 | HealthDataTypeTests.swift, HealthSampleMapperTests.swift |
| ✅ test: add 34 test files to increase coverage from 14% to ~90% | 2026-02-21 | See commit |
| ✅ chore: remove build artifacts from git tracking | 2026-02-21 | See commit |
| ✅ fix: enable macOS Catalyst build and resolve Info.plist warnings | 2026-02-21 | See commit |
| ✅ chore: add .gitignore for logs, plans, and build artifacts | 2026-02-21 | See commit |
| ✅ chore: update STATE.md with session progress | 2026-02-21 | See commit |
| ✅ Fix concurrency warnings, CloudKit entitlement, and widget config | 2026-02-21 | ExportService.swift, MQTTAutomation.swift, project.yml, entitlements, Info.plist, Widget/Info.plist |
| ✅ Enable macOS Mac Catalyst build | 2026-02-21 | project.pbxproj, BackgroundSyncService.swift, SyncActivityAttributes.swift |
| ✅ Fix Info.plist warnings (version, orientations, launch screen) | 2026-02-21 | App/Info.plist, Widget/Info.plist |

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
| Date | Duration | Work Done | Next Steps |
|------|----------|-----------|------------|
| _No sessions yet_ | - | - | - |

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
| `README.md` | Project documentation | Created 2026-02-22 |
| `CLAUDE.md` | Project guidance | Read at session start |
| `STATE.md` | This file | Auto-updated |
| `ServiceContainer.swift` | DI container | All services + ViewModel factories |
| `HealthDataType.swift` | 180+ type enum | Maps to HK identifiers, display names, categories |
| `HealthKitService.swift` | Core HealthKit actor | Fetch samples, routes, heart rate |
| `ExportService.swift` | Export pipeline actor | Fetch -> format -> write temp file |
| `NetworkServer.swift` | TLS HTTP server actor | /status, /pair, /health/types, /health/data |
| `BackgroundSyncService.swift` | BGTask + observer queries | Orchestrates sync + CloudKit + automations |
| `AutomationScheduler.swift` | Automation trigger engine | HKObserverQuery + interval timers |

## Metrics

<!-- Project health indicators -->
- **Source Files:** 85 Swift files across 15 directories
- **Health Data Types:** 180+ (quantity, category, correlation, characteristic, workout)
- **Tests:** 550 unit tests, 9 UI tests (44 test files)
- **Test Coverage:** ~90% file coverage
- **Build:** Passing (iOS + macOS Catalyst, 0 errors)
- **App Store Readiness:** HealthKit entitlement, camera description, encryption declaration, device capabilities — all added
- **Accessibility:** ~90%+ (labels/identifiers on all interactive elements)
- **Export Formats:** 4 (JSON flat, JSON grouped, CSV, GPX)
- **Automation Types:** 5 (REST, MQTT, Home Assistant, Cloud Storage, Calendar)
- **Siri Shortcuts:** 3 (Get value, Sync, Export)
- **API Endpoints:** 4 (/status, /api/v1/pair, /health/types, /health/data)
- **Last Successful Build:** 2026-02-22

---
*This file is updated automatically by Claude. Manual edits are preserved.*
