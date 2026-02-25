import Foundation
import WatchConnectivity

// MARK: - Watch Connectivity Manager

/// Receives data from the iPhone app via WatchConnectivity.
/// Updates WidgetDataStore when new data arrives.
class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {

    // MARK: - Published State

    @Published var isReachable = false

    // MARK: - Init

    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        processReceivedData(applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        processReceivedData(userInfo)
    }

    // MARK: - Data Processing

    private func processReceivedData(_ data: [String: Any]) {
        let store = WidgetDataStore.shared

        if let snapshotData = data["metric_snapshots"] as? Data,
           let snapshots = try? JSONDecoder().decode([WidgetMetricSnapshot].self, from: snapshotData) {
            store.save(snapshots)
        }

        if let streakData = data["streak_data"] as? [String: Int] {
            store.saveStreakData(streakData)
        }

        if let goalData = data["goal_progress"] as? [String: Double] {
            store.saveGoalProgress(goalData)
        }
    }
}
