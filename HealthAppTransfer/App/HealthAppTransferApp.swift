import SwiftData
import SwiftUI

@main
struct HealthAppTransferApp: App {

    // MARK: - State

    private let modelContainer: ModelContainer

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
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
