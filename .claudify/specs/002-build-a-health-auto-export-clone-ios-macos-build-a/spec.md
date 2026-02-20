# build-a-health-auto-export-clone-ios-macos-build-a

## Task
Build a Health Auto Export Clone (iOS + macOS). Build an iOS + macOS app replicating Health Auto Export (healthyapps.dev). Reads all Apple HealthKit data and makes it exportable, syncable, and automatable with zero server dependency. Use ai-health-sync-ios (github.com/mneves75/ai-health-sync-ios, Apache 2.0) as the foundation. Extend it; don't rebuild from scratch. Stack: Swift 6, SwiftUI multiplatform, SwiftData, actor-based concurrency. Network.framework for TLS server, URLSession for outbound HTTP, CocoaMQTT for MQTT. CryptoKit + Keychain for security. Swift Charts, MapKit, WidgetKit, ActivityKit, CloudKit. What to Build: 1. Extend HealthKit coverage to 150+ types. 2. Export formats: JSON v1+v2, CSV, GPX. Aggregation engine. 3. Automations: REST API, MQTT, Home Assistant, Cloud storage, Calendar, Local network. 4. Background sync: BGTaskScheduler + HKObserverQuery. 5. Mac companion via CloudKit + LAN sync. 6. Widgets + Live Activities. 7. Quick Export with share sheet + Shortcuts. 8. Visualization with Swift Charts + MapKit. Security: mTLS, QR pairing, Keychain, FaceID/TouchID. Phases: extend types, aggregation+automation, integrations, charts+widgets, CloudKit+macOS, onboarding+localization. Privacy non-negotiable. Offline-first. VoiceOver + Dynamic Type.

## Status
failed

## Created
2026-02-20T12:05:30.225625+00:00
