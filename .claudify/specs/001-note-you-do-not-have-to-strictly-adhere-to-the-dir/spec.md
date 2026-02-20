# note-you-do-not-have-to-strictly-adhere-to-the-dir

## Task
Note, you do not have to strictly adhere to the directions here, you are the professional: Build a Health Auto Export Clone (iOS + macOS)
Build an iOS + macOS app replicating Health Auto Export (healthyapps.dev). Reads all Apple HealthKit data and makes it exportable, syncable, and automatable with zero server dependency.
Use ai-health-sync-ios (github.com/mneves75/ai-health-sync-ios, Apache 2.0) as the foundation — it has a working Swift 6 actor-based architecture with HealthKit access, TLS 1.3 local network server, QR pairing, SwiftData persistence, and audit logging. Extend it; don't rebuild from scratch.
Stack
Swift 6, SwiftUI multiplatform, SwiftData, actor-based concurrency (async/await). Network.framework for TLS server, URLSession for outbound HTTP, CocoaMQTT for MQTT. CryptoKit + Keychain for security. Swift Charts, MapKit, WidgetKit, ActivityKit, CloudKit.
What to Build
1. Extend HealthKit coverage from ai-health-sync-ios's 31 types to 150+: activity (steps, energy, distance, VO2 max, cycling/running/swimming metrics), body measurements, heart (HR, HRV, BP, AFib), hearing, nutrition (36 types), mindfulness, mobility, reproductive health, respiratory, sleep (phases: REM/core/deep/awake), vitals, ECG, symptoms, medications, workouts (70+ HKWorkoutActivityType with routes, splits, metadata), clinical records.
2. Export formats: JSON (v1 flat HealthSampleDTO-compatible + v2 rich nested), CSV (RFC 4180), GPX (workout routes with HR extensions). Aggregation: raw/minutes/hours/days/weeks/months/years with metric-appropriate math (steps=sum, HR=avg/min/max).
3. Automations — saved configs (what data + format + aggregation + destination):

REST API: POST with configurable headers/auth, retry with backoff
MQTT: v3.1.1/v5.0, per-metric subtopics, configurable broker/QoS/TLS
Home Assistant: sensor entities via HA REST API
Cloud storage: iCloud Drive, Google Drive (OAuth), Dropbox (OAuth)
Calendar: milestone events with configurable thresholds
Local network: extend ai-health-sync-ios's TLS server with export-format endpoints

4. Background sync: BGTaskScheduler + HKObserverQuery + interactive widgets as supplementary triggers. Queue failures, retry on next opportunity. Always check protectedDataAvailable (HealthKit inaccessible when locked).
5. Mac companion: CloudKit private DB incremental sync + direct LAN sync (extend existing TLS model). SwiftUI dashboard with charts, metric browser, workout maps.
6. Widgets: WidgetKit (small/medium/large, any metric, sparklines, interactive sync trigger), Lock Screen, Live Activities (sync status), StandBy.
7. Quick Export: select metrics + date range + format → share sheet. Shortcuts actions. Zip compression.
8. Visualization: Swift Charts per metric, trend analysis (7/30-day moving avg), correlation overlay, workout detail with MapKit route + HR + elevation.
Data Models
Keep ai-health-sync-ios's existing models (PairedDevice, AuditEventRecord, SyncConfiguration). Add: Automation (destination, metrics, format, aggregation, schedule, status), SyncLog (per-export history), ExportTemplate (saved quick-export presets).
Security
Preserve ai-health-sync-ios's model: mTLS ECDSA P-256, QR pairing (8-char code, 5min TTL, 5 max attempts), SHA256-hashed bearer tokens (30-day expiry), constant-time comparison, anonymized device names, audit logging (health values never logged, IPs redacted, 90-day retention). All credentials in Keychain. Optional FaceID/TouchID lock.
Phases

Extend HealthDataType enum to 150+, extend mapper/service, metric browser UI, manual JSON+CSV export
Aggregation engine, automation model + CRUD, REST API + iCloud destinations, background pipeline, Shortcuts
MQTT, Home Assistant, Google Drive, Dropbox, Calendar, extended network server endpoints
Charts, workout detail, widgets, Live Activities
CloudKit sync, macOS app, watchOS companion
Onboarding, GPX, Spotlight, localization

Constraints
Privacy non-negotiable (no analytics/tracking/telemetry). Quick Export <10s. Offline-first. Full VoiceOver + Dynamic Type. Actor isolation everywhere. Minimize third-party deps. Never crash on auth denial or network failure. Export v1 always supported alongside v2.

## Status
discarded

## Created
2026-02-20T11:58:38.045481+00:00
