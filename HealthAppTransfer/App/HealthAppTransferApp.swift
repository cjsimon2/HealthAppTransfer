import SwiftData
import SwiftUI

#if canImport(UIKit)
import BackgroundTasks
#endif

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

@main
struct HealthAppTransferApp: App {

    // MARK: - State

    private let modelContainer: ModelContainer
    private let services: ServiceContainer
    private let backgroundSync: BackgroundSyncService
    private let automationScheduler: AutomationScheduler

    #if os(macOS)
    @State private var selectedExportTab = false
    #endif

    // MARK: - Init

    init() {
        let services = ServiceContainer()
        self.services = services

        do {
            let container = try PersistenceConfiguration.makeModelContainer()
            self.modelContainer = container
            self.backgroundSync = BackgroundSyncService(
                healthKitService: services.healthKitService,
                modelContainer: container
            )
            self.automationScheduler = AutomationScheduler(
                healthKitService: services.healthKitService,
                modelContainer: container,
                keychain: services.keychain
            )
        } catch {
            // Attempt recovery by deleting the corrupt store and recreating
            Loggers.persistence.error("ModelContainer creation failed, attempting recovery: \(error.localizedDescription)")
            do {
                let container = try PersistenceConfiguration.makeModelContainer(deleteExisting: true)
                self.modelContainer = container
                self.backgroundSync = BackgroundSyncService(
                    healthKitService: services.healthKitService,
                    modelContainer: container
                )
                self.automationScheduler = AutomationScheduler(
                    healthKitService: services.healthKitService,
                    modelContainer: container,
                    keychain: services.keychain
                )
            } catch {
                fatalError("Failed to create ModelContainer even after recovery: \(error)")
            }
        }

        #if canImport(UIKit)
        BackgroundSyncService.registerBackgroundTasks(service: backgroundSync)
        #endif
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView(services: services)
                .tint(AppColors.primary)
                .task { await startBackgroundSync() }
        }
        .modelContainer(modelContainer)
        #if os(macOS)
        .commands {
            macOSCommands
        }
        #endif
    }

    // MARK: - macOS Commands

    #if os(macOS)
    @CommandsBuilder
    private var macOSCommands: some Commands {
        CommandGroup(replacing: .newItem) {
            // Remove default "New" since it doesn't apply
        }

        CommandMenu("Sync") {
            Button("Sync via CloudKit Now") {
                Task { await performCloudKitSync() }
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
        }

        CommandMenu("Export") {
            Button("Export Health Data...") {
                NotificationCenter.default.post(name: .macNavigateToExport, object: nil)
            }
            .keyboardShortcut("e", modifiers: [.command])

            Divider()

            Button("Quick Export as JSON") {
                NotificationCenter.default.post(
                    name: .macQuickExport,
                    object: ExportFormat.jsonV2
                )
            }
            .keyboardShortcut("j", modifiers: [.command, .shift])

            Button("Quick Export as CSV") {
                NotificationCenter.default.post(
                    name: .macQuickExport,
                    object: ExportFormat.csv
                )
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
        }
    }
    #endif

    // MARK: - Background Sync

    private func startBackgroundSync() async {
        // Wire automation scheduler into background sync
        await backgroundSync.setAutomationScheduler(automationScheduler)
        await automationScheduler.start()

        #if os(iOS) && !targetEnvironment(macCatalyst)
        await backgroundSync.setupObserverQueries()
        await backgroundSync.scheduleAppRefresh()
        activateWatchSession()
        #else
        // On macOS / Mac Catalyst, pull data from CloudKit on launch
        await performCloudKitSync()
        #endif
    }

    // MARK: - Watch Connectivity

    #if canImport(WatchConnectivity)
    private func activateWatchSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        if session.delegate == nil {
            session.delegate = PhoneSessionDelegate.shared
        }
        session.activate()
    }
    #endif

    // MARK: - CloudKit Sync

    private func performCloudKitSync() async {
        let cloudKitSync = CloudKitSyncService(
            healthKitService: services.healthKitService,
            modelContainer: modelContainer
        )

        do {
            let samples = try await cloudKitSync.downloadSamples()
            Loggers.cloudKit.info("macOS CloudKit sync: downloaded \(samples.count) samples")
        } catch {
            Loggers.cloudKit.error("macOS CloudKit sync failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Phone Session Delegate

#if canImport(WatchConnectivity)
/// WCSession delegate for the iPhone side — pushes widget data to the watch.
class PhoneSessionDelegate: NSObject, WCSessionDelegate {

    static let shared = PhoneSessionDelegate()

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            pushDataToWatch(session: session)
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func pushDataToWatch(session: WCSession? = nil) {
        let wcSession = session ?? WCSession.default
        guard wcSession.activationState == .activated, wcSession.isPaired else { return }

        let store = WidgetDataStore.shared
        var context: [String: Any] = [:]

        if let snapshotData = try? JSONEncoder().encode(store.loadAll()) {
            context["metric_snapshots"] = snapshotData
        }

        let streakData = store.loadStreakData()
        if !streakData.isEmpty { context["streak_data"] = streakData }

        let goalData = store.loadGoalProgress()
        if !goalData.isEmpty { context["goal_progress"] = goalData }

        guard !context.isEmpty else { return }
        try? wcSession.updateApplicationContext(context)
    }
}
#endif

// MARK: - macOS Notification Names

#if os(macOS)
extension Notification.Name {
    /// Navigate to the Export tab in MainTabView.
    static let macNavigateToExport = Notification.Name("macNavigateToExport")

    /// Trigger a quick export with the format in the notification's object.
    static let macQuickExport = Notification.Name("macQuickExport")
}
#endif
