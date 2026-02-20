# WidgetKit Patterns

## Basic Widget Structure

### Widget Definition
```swift
import WidgetKit
import SwiftUI

@main
struct MyWidget: Widget {
    let kind: String = "MyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MyWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("My Widget")
        .description("Shows important information at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
```

### Timeline Entry
```swift
struct SimpleEntry: TimelineEntry {
    let date: Date
    let value: Int
    let title: String
}
```

### Timeline Provider
```swift
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), value: 0, title: "Loading...")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        // Return sample data for widget gallery
        let entry = SimpleEntry(date: Date(), value: 42, title: "Tasks")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        var entries: [SimpleEntry] = []
        let currentDate = Date()

        // Create entries for next 5 hours
        for hourOffset in 0..<5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, value: 42 + hourOffset, title: "Tasks")
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}
```

## Configurable Widgets

### Intent Configuration
```swift
import AppIntents

struct SelectCategoryIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Category"
    static var description = IntentDescription("Choose which category to display")

    @Parameter(title: "Category")
    var category: CategoryEntity?
}

struct CategoryEntity: AppEntity {
    var id: String
    var name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static var defaultQuery = CategoryQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct CategoryQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CategoryEntity] {
        // Fetch categories by IDs
        return identifiers.compactMap { id in
            // Return matching categories
            CategoryEntity(id: id, name: "Category \(id)")
        }
    }

    func suggestedEntities() async throws -> [CategoryEntity] {
        // Return available categories
        return [
            CategoryEntity(id: "1", name: "Work"),
            CategoryEntity(id: "2", name: "Personal"),
            CategoryEntity(id: "3", name: "Shopping")
        ]
    }
}
```

### Intent-Based Widget
```swift
struct ConfigurableWidget: Widget {
    let kind = "ConfigurableWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectCategoryIntent.self, provider: ConfigurableProvider()) { entry in
            ConfigurableWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Category Widget")
        .description("Shows items from a selected category")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct ConfigurableProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ConfigurableEntry {
        ConfigurableEntry(date: Date(), category: nil, items: [])
    }

    func snapshot(for configuration: SelectCategoryIntent, in context: Context) async -> ConfigurableEntry {
        ConfigurableEntry(date: Date(), category: configuration.category, items: ["Sample Item"])
    }

    func timeline(for configuration: SelectCategoryIntent, in context: Context) async -> Timeline<ConfigurableEntry> {
        let items = await fetchItems(for: configuration.category)
        let entry = ConfigurableEntry(date: Date(), category: configuration.category, items: items)
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
    }

    private func fetchItems(for category: CategoryEntity?) async -> [String] {
        // Fetch items from your data source
        return ["Item 1", "Item 2", "Item 3"]
    }
}
```

## Widget Views

### Size-Adaptive Views
```swift
struct MyWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .accessoryCircular:
            CircularWidgetView(entry: entry)
        case .accessoryRectangular:
            RectangularWidgetView(entry: entry)
        case .accessoryInline:
            InlineWidgetView(entry: entry)
        @unknown default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: SimpleEntry

    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.title)
                .font(.headline)
            Spacer()
            Text("\(entry.value)")
                .font(.system(.largeTitle, design: .rounded).bold())
        }
        .padding()
    }
}
```

### Deep Links
```swift
struct TaskWidgetView: View {
    let task: Task

    var body: some View {
        Link(destination: URL(string: "myapp://task/\(task.id)")!) {
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                Text(task.dueDate, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Handle in main app
struct ContentView: View {
    var body: some View {
        NavigationStack {
            // ...
        }
        .onOpenURL { url in
            if url.scheme == "myapp", url.host == "task" {
                let taskId = url.lastPathComponent
                // Navigate to task
            }
        }
    }
}
```

## Data Sharing

### App Groups
```swift
// In both app and widget extension targets, add App Group capability
// Then use shared UserDefaults

class SharedData {
    static let shared = SharedData()

    private let defaults = UserDefaults(suiteName: "group.com.yourapp.shared")

    var taskCount: Int {
        get { defaults?.integer(forKey: "taskCount") ?? 0 }
        set { defaults?.set(newValue, forKey: "taskCount") }
    }

    var lastUpdate: Date? {
        get { defaults?.object(forKey: "lastUpdate") as? Date }
        set { defaults?.set(newValue, forKey: "lastUpdate") }
    }
}
```

### Shared Core Data
```swift
class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "Model")

        // Use shared app group container
        let storeURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.yourapp.shared")!
            .appendingPathComponent("Model.sqlite")

        let description = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
    }
}
```

## Timeline Policies

### Refresh Strategies
```swift
// Refresh at specific time
let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
let timeline = Timeline(entries: entries, policy: .after(nextUpdate))

// Refresh at end of entries
let timeline = Timeline(entries: entries, policy: .atEnd)

// Never automatically refresh
let timeline = Timeline(entries: entries, policy: .never)
```

### Manual Refresh
```swift
import WidgetKit

// From your main app
WidgetCenter.shared.reloadTimelines(ofKind: "MyWidget")

// Reload all widgets
WidgetCenter.shared.reloadAllTimelines()
```

## Lock Screen Widgets (iOS 16+)

### Accessory Family Views
```swift
struct LockScreenWidget: Widget {
    let kind = "LockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Stats")
        .description("View stats on your Lock Screen")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

struct LockScreenWidgetView: View {
    let entry: SimpleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: Double(entry.value), in: 0...100) {
                Image(systemName: "checkmark")
            }
            .gaugeStyle(.accessoryCircularCapacity)

        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Text("Tasks")
                    .font(.headline)
                Text("\(entry.value) remaining")
                    .font(.caption)
            }

        case .accessoryInline:
            Text("\(entry.value) tasks")

        @unknown default:
            Text("\(entry.value)")
        }
    }
}
```

## Interactive Widgets (iOS 17+)

### Button Actions
```swift
struct TaskToggleIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Task"

    @Parameter(title: "Task ID")
    var taskId: String

    func perform() async throws -> some IntentResult {
        // Toggle task completion in your data store
        await TaskManager.shared.toggleTask(id: taskId)
        return .result()
    }
}

struct InteractiveWidgetView: View {
    let task: Task

    var body: some View {
        HStack {
            Button(intent: TaskToggleIntent(taskId: task.id)) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(.plain)

            Text(task.title)
                .strikethrough(task.isCompleted)
        }
    }
}
```

## Best Practices

1. **Keep it glanceable** - Widgets should convey info at a glance
2. **Update judiciously** - Minimize timeline refreshes for battery
3. **Handle placeholder** - Show realistic placeholder during loading
4. **Support all sizes** - Adapt content to each widget family
5. **Test in widget gallery** - Ensure snapshot looks good
6. **Use deep links** - Connect widget taps to relevant app content
7. **Share data via App Groups** - Required for widget data access
8. **Consider redacted state** - Widgets show placeholder when locked
