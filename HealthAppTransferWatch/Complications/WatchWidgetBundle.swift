import WidgetKit
import SwiftUI

// MARK: - Watch Widget Bundle

/// Bundle containing all watchOS complications.
/// Note: This is a separate widget extension target — uses its own @main.
struct WatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakComplication()
        GoalProgressComplication()
    }
}
