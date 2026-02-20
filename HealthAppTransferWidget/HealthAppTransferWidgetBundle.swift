import SwiftUI
import WidgetKit

@main
struct HealthAppTransferWidgetBundle: WidgetBundle {
    var body: some Widget {
        SyncLiveActivity()
        HealthMetricWidget()
    }
}
