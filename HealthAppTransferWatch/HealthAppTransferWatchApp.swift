import SwiftUI

// MARK: - Watch App

@main
struct HealthAppTransferWatchApp: App {

    @StateObject private var connectivityManager = WatchConnectivityManager()

    var body: some Scene {
        WindowGroup {
            WatchDashboardView(connectivityManager: connectivityManager)
        }
    }
}
