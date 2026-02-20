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
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        #if canImport(UIKit)
        BackgroundSyncService.registerBackgroundTasks(service: backgroundSync)
        #endif
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView(services: services)
                .task { await startBackgroundSync() }
        }
        .modelContainer(modelContainer)
    }

    // MARK: - Background Sync

    private func startBackgroundSync() async {
        await backgroundSync.setupObserverQueries()
        #if canImport(UIKit)
        await backgroundSync.scheduleAppRefresh()
        #endif
    }
}
