/// Entry point for the HealthAppTransfer watchOS companion app.
///
/// Instantiates a single `WatchConnectivityManager` that keeps the watch in
/// sync with the iPhone, and passes it down to `WatchDashboardView`.
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
