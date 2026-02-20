# State Management Review Command

Review state management patterns in a SwiftUI file or feature.

## Target
$ARGUMENTS

## State Property Wrapper Reference

| Wrapper | Use Case | Ownership |
|---------|----------|-----------|
| `@State` | View-local value types | View owns |
| `@StateObject` | View creates ObservableObject | View owns |
| `@ObservedObject` | Passed-in ObservableObject | External owns |
| `@EnvironmentObject` | Deep hierarchy injection | Environment owns |
| `@Binding` | Two-way parent connection | Parent owns |
| `@Environment` | System values (colorScheme, etc) | System owns |

## Review Checklist

### Property Wrapper Selection

- [ ] `@State` only used for simple, view-local values
- [ ] `@StateObject` used when view creates the object
- [ ] `@ObservedObject` for objects passed in or singletons
- [ ] No `@StateObject` for singletons (use `@ObservedObject`)
- [ ] `@Binding` used for child view mutations

### Common Mistakes

#### 1. StateObject for Singletons
```swift
// WRONG - StateObject implies ownership
@StateObject var settings = AppSettings.shared

// RIGHT - ObservedObject for shared instances
@ObservedObject var settings = AppSettings.shared
```

#### 2. ObservedObject for Owned Objects
```swift
// WRONG - Object recreated each render
@ObservedObject var viewModel = ViewModel()

// RIGHT - StateObject preserves across renders
@StateObject var viewModel = ViewModel()
```

#### 3. State for Reference Types
```swift
// WRONG - @State is for value types
@State var viewModel = SomeClass()

// RIGHT - Use @StateObject for classes
@StateObject var viewModel = SomeClass()
```

### Data Flow Patterns

#### Parent to Child
```swift
struct ParentView: View {
    @State private var count = 0

    var body: some View {
        ChildView(count: $count)  // Pass binding
    }
}

struct ChildView: View {
    @Binding var count: Int  // Receive binding
}
```

#### Shared State (Singleton)
```swift
@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    @Published var isLoggedIn = false
}

struct MyView: View {
    @ObservedObject var appState = AppState.shared
}
```

#### Environment Injection
```swift
// In App or root view
ContentView()
    .environmentObject(dataStore)

// In child view (any depth)
struct ChildView: View {
    @EnvironmentObject var dataStore: DataStore
}
```

### ViewModel Patterns

#### Standard ViewModel
```swift
@MainActor
class FeatureViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var error: Error?

    func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        // Load items...
    }
}

struct FeatureView: View {
    @StateObject private var viewModel = FeatureViewModel()

    var body: some View {
        List(viewModel.items) { item in
            // ...
        }
        .task { await viewModel.loadItems() }
    }
}
```

### Issues to Flag

1. **State recreated on parent re-render** - Move to parent or use `@StateObject`
2. **Unnecessary state** - Can it be derived from other state?
3. **State in wrong place** - Should it be higher in hierarchy?
4. **Missing @MainActor** - ViewModels should be `@MainActor`
5. **Direct property mutation** - Use methods for complex updates

## Output Format

1. State flow diagram (text-based)
2. Issues found with severity
3. Recommended refactoring with code
4. Alternative patterns to consider
