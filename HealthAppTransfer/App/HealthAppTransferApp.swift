import SwiftData
import SwiftUI

#if canImport(UIKit)
import BackgroundTasks
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
        #else
        // On macOS / Mac Catalyst, pull data from CloudKit on launch
        await performCloudKitSync()
        #endif
    }

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

// MARK: - macOS Notification Names

#if os(macOS)
extension Notification.Name {
    /// Navigate to the Export tab in MainTabView.
    static let macNavigateToExport = Notification.Name("macNavigateToExport")

    /// Trigger a quick export with the format in the notification's object.
    static let macQuickExport = Notification.Name("macQuickExport")
}
#endif
