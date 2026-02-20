# watchOS Development Patterns

## App Structure

### Basic watchOS App
```swift
import SwiftUI

@main
struct MyWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### With Notifications
```swift
@main
struct MyWatchApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
```

## Layout Patterns

### Compact Layouts
```swift
struct WorkoutView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Active Calories")
                .font(.caption2)
                .foregroundColor(.secondary)

            Text("245")
                .font(.system(.title, design: .rounded).weight(.bold))

            Text("cal")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
```

### List-Based Navigation
```swift
struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Today") {
                    TodayView()
                }
                NavigationLink("History") {
                    HistoryView()
                }
                NavigationLink("Settings") {
                    SettingsView()
                }
            }
            .navigationTitle("My App")
        }
    }
}
```

### TabView for Paging
```swift
struct WorkoutDashboard: View {
    var body: some View {
        TabView {
            MetricsView()
            ControlsView()
            NowPlayingView()
        }
        .tabViewStyle(.verticalPage)
    }
}
```

## Complications

### Complication Provider
```swift
import WidgetKit
import SwiftUI

struct MyComplication: Widget {
    let kind: String = "MyComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ComplicationView(entry: entry)
        }
        .configurationDisplayName("My App")
        .description("Shows current status")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner
        ])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), value: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date(), value: 42))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date(), value: 42)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }
}
```

### Complication Views
```swift
struct ComplicationView: View {
    let entry: SimpleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularView(value: entry.value)
        case .accessoryRectangular:
            RectangularView(value: entry.value)
        case .accessoryInline:
            Text("Value: \(entry.value)")
        case .accessoryCorner:
            CornerView(value: entry.value)
        @unknown default:
            Text("\(entry.value)")
        }
    }
}

struct CircularView: View {
    let value: Int

    var body: some View {
        Gauge(value: Double(value), in: 0...100) {
            Text("\(value)")
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }
}
```

## Connectivity

### Watch Connectivity
```swift
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var receivedMessage: [String: Any] = [:]

    private override init() {
        super.init()

        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendMessage(_ message: [String: Any]) {
        guard WCSession.default.isReachable else { return }

        WCSession.default.sendMessage(message) { reply in
            print("Reply: \(reply)")
        } errorHandler: { error in
            print("Error: \(error)")
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Handle activation
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.receivedMessage = message
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
```

## HealthKit Integration

### Request Authorization
```swift
import HealthKit

class HealthKitManager {
    let healthStore = HKHealthStore()

    func requestAuthorization() async throws {
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
    }
}
```

### Workout Session
```swift
import HealthKit

class WorkoutManager: NSObject, ObservableObject {
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?

    @Published var heartRate: Double = 0
    @Published var calories: Double = 0

    func startWorkout(type: HKWorkoutActivityType) async throws {
        let config = HKWorkoutConfiguration()
        config.activityType = type
        config.locationType = .outdoor

        session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
        builder = session?.associatedWorkoutBuilder()

        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)

        session?.delegate = self
        builder?.delegate = self

        let startDate = Date()
        session?.startActivity(with: startDate)
        try await builder?.beginCollection(at: startDate)
    }

    func pauseWorkout() {
        session?.pause()
    }

    func resumeWorkout() {
        session?.resume()
    }

    func endWorkout() async throws {
        session?.end()
        try await builder?.endCollection(at: Date())
        try await builder?.finishWorkout()
    }
}

extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        // Handle state changes
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        // Handle errors
    }
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }

            let statistics = workoutBuilder.statistics(for: quantityType)

            DispatchQueue.main.async {
                switch quantityType {
                case HKQuantityType.quantityType(forIdentifier: .heartRate):
                    let unit = HKUnit.count().unitDivided(by: .minute())
                    self.heartRate = statistics?.mostRecentQuantity()?.doubleValue(for: unit) ?? 0

                case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                    let unit = HKUnit.kilocalorie()
                    self.calories = statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0

                default:
                    break
                }
            }
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle events
    }
}
```

## Performance Considerations

### Memory Limits
```swift
// watchOS has limited memory (~30-50MB)
// - Load data on demand
// - Release unused resources
// - Use thumbnails for images

struct ImageView: View {
    let imageURL: URL

    var body: some View {
        AsyncImage(url: imageURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ProgressView()
        }
        .frame(width: 50, height: 50)  // Keep images small
        .clipShape(Circle())
    }
}
```

### Background Tasks
```swift
import WatchKit

class ExtensionDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        // Schedule background refresh
        scheduleBackgroundRefresh()
    }

    func scheduleBackgroundRefresh() {
        let fireDate = Date().addingTimeInterval(15 * 60)  // 15 minutes
        WKApplication.shared().scheduleBackgroundRefresh(withPreferredDate: fireDate, userInfo: nil) { error in
            if let error = error {
                print("Failed to schedule: \(error)")
            }
        }
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let refreshTask as WKApplicationRefreshBackgroundTask:
                // Perform refresh
                scheduleBackgroundRefresh()
                refreshTask.setTaskCompletedWithSnapshot(false)

            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
```

## Best Practices

1. **Keep UI simple** - Small screen, glanceable information
2. **Minimize text input** - Use voice, selection, or iPhone input
3. **Optimize for battery** - Limit background work
4. **Use complications** - Primary way users interact with watch apps
5. **Test on device** - Simulator doesn't match real performance
6. **Handle connectivity changes** - iPhone may not always be reachable
7. **Support Always On** - Consider dimmed state appearance
