# Widget Review Command

Review WidgetKit implementation for best practices.

## Target
$ARGUMENTS

## Widget Architecture

### Timeline Provider
```swift
struct MyWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MyEntry {
        MyEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (MyEntry) -> ()) {
        completion(MyEntry(date: Date(), data: loadData()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MyEntry>) -> ()) {
        let entry = MyEntry(date: Date(), data: loadData())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
```

### Timeline Entry
```swift
struct MyEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}
```

### Widget View
```swift
struct MyWidgetView: View {
    var entry: MyEntry

    var body: some View {
        // Widget content
    }
}
```

## Review Checklist

### Data Sharing
- [ ] Using App Group for data sharing
- [ ] UserDefaults suite name matches app
- [ ] Data format efficient for widget
- [ ] Sensitive data not exposed

### App Group Setup
```swift
// In both app and widget
let defaults = UserDefaults(suiteName: "group.com.yourapp")
```

### Timeline Management
- [ ] Appropriate refresh policy
- [ ] Not refreshing too frequently (battery)
- [ ] Placeholder shows meaningful content
- [ ] Snapshot loads quickly

### Widget Sizes
- [ ] Small widget supported
- [ ] Medium widget supported (if applicable)
- [ ] Large widget supported (if applicable)
- [ ] Each size optimized for content

### Performance
- [ ] No network calls in timeline provider
- [ ] Data pre-computed by app
- [ ] Images properly sized
- [ ] Minimal memory usage

### Deep Links
```swift
// Widget view with deep link
Link(destination: URL(string: "myapp://action")!) {
    WidgetContent()
}

// Or using widgetURL for simple cases
.widgetURL(URL(string: "myapp://action"))
```

### URL Scheme
- [ ] App handles widget URLs
- [ ] Deep links work correctly
- [ ] URL scheme registered in Info.plist

## Common Issues

### 1. Data Not Updating
```swift
// In main app, after data changes:
WidgetCenter.shared.reloadAllTimelines()
// Or for specific widget:
WidgetCenter.shared.reloadTimelines(ofKind: "MyWidget")
```

### 2. No App Group Access
```swift
// WRONG - Using standard UserDefaults
UserDefaults.standard.set(value, forKey: "key")

// RIGHT - Using App Group
let defaults = UserDefaults(suiteName: "group.com.yourapp")
defaults?.set(value, forKey: "key")
```

### 3. Too Frequent Updates
```swift
// WRONG - Updates every minute (bad for battery)
.after(Calendar.current.date(byAdding: .minute, value: 1, to: Date())!)

// RIGHT - Appropriate interval
.after(Calendar.current.date(byAdding: .minute, value: 15, to: Date())!)
// Or .atEnd for less frequent updates
```

### 4. Missing Placeholder
```swift
// Placeholder should be meaningful
func placeholder(in context: Context) -> MyEntry {
    MyEntry(date: Date(), data: .placeholder)  // Not empty!
}
```

## Lock Screen Widgets (iOS 16+)

### Widget Families
```swift
@main
struct MyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MyWidget", provider: Provider()) { entry in
            MyWidgetView(entry: entry)
        }
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,     // Lock screen
            .accessoryRectangular,  // Lock screen
            .accessoryInline,       // Lock screen
        ])
    }
}
```

### Lock Screen Styling
```swift
struct LockScreenView: View {
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularView()
        case .accessoryRectangular:
            RectangularView()
        case .accessoryInline:
            InlineView()
        default:
            HomeScreenView()
        }
    }
}
```

## Output

1. Widget architecture review
2. Data sharing issues
3. Performance concerns
4. Missing widget families
5. Recommended improvements
