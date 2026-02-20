# Preview Fix Command

Fix SwiftUI preview issues and crashes.

## Target View
$ARGUMENTS

## Common Preview Issues

### 1. Missing Environment Objects

```swift
// CRASH - Missing EnvironmentObject
struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        MyView()  // Crashes if view uses @EnvironmentObject
    }
}

// FIXED
struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        MyView()
            .environmentObject(MyStore.preview)
    }
}
```

### 2. Missing Model Context (SwiftData)

```swift
// CRASH - No model context
struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        TaskListView()
    }
}

// FIXED
struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        TaskListView()
            .modelContainer(previewContainer)
    }

    static var previewContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: TaskItem.self, configurations: config)
        // Add sample data
        container.mainContext.insert(TaskItem.sample)
        return container
    }()
}
```

### 3. Network/Async Dependencies

```swift
// CRASH - Network call in init
class MyViewModel: ObservableObject {
    init() {
        Task { await loadData() }  // May crash in preview
    }
}

// FIXED - Conditional loading
class MyViewModel: ObservableObject {
    init(loadOnInit: Bool = true) {
        if loadOnInit {
            Task { await loadData() }
        }
    }

    static var preview: MyViewModel {
        let vm = MyViewModel(loadOnInit: false)
        vm.items = [.sample]
        return vm
    }
}
```

### 4. Singleton Dependencies

```swift
// May crash or behave unexpectedly
struct MyView: View {
    @ObservedObject var settings = AppSettings.shared
}

// FIXED - Preview with mock
struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        MyView()
    }
}

// Or create preview-specific singleton state
extension AppSettings {
    static var preview: AppSettings {
        let settings = AppSettings()
        settings.darkMode = true
        return settings
    }
}
```

### 5. Device-Specific Code

```swift
// May crash on preview
UIDevice.current.userInterfaceIdiom

// FIXED - Guard for preview
#if targetEnvironment(simulator)
// Preview-safe code
#endif
```

## Preview Best Practices

### Multiple Configurations
```swift
struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MyView()
                .previewDisplayName("Light")

            MyView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")

            MyView()
                .environment(\.sizeCategory, .accessibilityLarge)
                .previewDisplayName("Large Text")
        }
    }
}
```

### Preview Devices
```swift
struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        MyView()
            .previewDevice("iPhone 15 Pro")

        MyView()
            .previewDevice("iPad Pro (12.9-inch)")
    }
}
```

### Sample Data Extension
```swift
extension TaskItem {
    static var sample: TaskItem {
        TaskItem(title: "Sample Task", isCompleted: false)
    }

    static var samples: [TaskItem] {
        [
            TaskItem(title: "Task 1", isCompleted: false),
            TaskItem(title: "Task 2", isCompleted: true),
        ]
    }
}
```

## Debug Preview Crashes

1. **Check Console:** Look for crash logs in Xcode console
2. **Simplify View:** Comment out sections until preview works
3. **Check Dependencies:** Verify all injected dependencies exist
4. **Restart Canvas:** Editor > Canvas > Refresh All Previews
5. **Clear Derived Data:** If persistent issues

## Checklist

- [ ] All environment objects provided
- [ ] Model context injected (SwiftData)
- [ ] Network calls optional in preview
- [ ] Sample data available
- [ ] Multiple device sizes tested
- [ ] Light and dark mode previews

## Output

1. Identified preview issues
2. Missing dependencies
3. Fixed preview code
4. Sample data to add
