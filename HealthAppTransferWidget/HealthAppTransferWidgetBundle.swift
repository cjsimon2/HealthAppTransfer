/// Widget extension bundle for HealthAppTransfer.
///
/// Registers the Live Activity, the configurable health-metric widget, and the
/// Insight of the Day widget with the system widget infrastructure.
import SwiftUI
import WidgetKit

@main
struct HealthAppTransferWidgetBundle: WidgetBundle {
    var body: some Widget {
        SyncLiveActivity()
        HealthMetricWidget()
        InsightOfDayWidget()
    }
}
