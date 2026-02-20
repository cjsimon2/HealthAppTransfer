import SwiftData
import SwiftUI

@main
struct HealthAppTransferApp: App {

    // MARK: - State

    private let modelContainer: ModelContainer
    private let services = ServiceContainer()

    // MARK: - Init

    init() {
        do {
            modelContainer = try PersistenceConfiguration.makeModelContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView(services: services)
        }
        .modelContainer(modelContainer)
    }
}
