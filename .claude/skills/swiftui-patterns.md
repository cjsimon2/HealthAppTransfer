# SwiftUI Best Practices

## View Structure

### Standard View Template
```swift
struct MyView: View {
    // MARK: - Environment
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme

    // MARK: - Observed Objects
    @ObservedObject var viewModel: MyViewModel

    // MARK: - State
    @State private var isLoading = false
    @State private var showingSheet = false

    // MARK: - Body
    var body: some View {
        content
            .onAppear { viewModel.loadData() }
    }

    // MARK: - Subviews
    private var content: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                mainContent
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)  // Tab bar clearance
        }
    }

    private var headerSection: some View { /* ... */ }
    private var mainContent: some View { /* ... */ }
}
```

## State Management

### Property Wrapper Selection
| Wrapper | Use Case | Ownership |
|---------|----------|-----------|
| `@State` | View-local value types | View owns |
| `@StateObject` | View creates ObservableObject | View owns |
| `@ObservedObject` | Passed-in or singleton ObservableObject | External owns |
| `@EnvironmentObject` | Deep hierarchy injection | Environment owns |
| `@Binding` | Two-way parent connection | Parent owns |

### Singleton Pattern
```swift
// Always use @ObservedObject for singletons
@ObservedObject var settings = AppSettings.shared

// Never @StateObject for singletons
// @StateObject var settings = AppSettings.shared  // WRONG
```

## Layout Patterns

### Spacing Scale
- Extra Small: 4pt
- Small: 8pt
- Medium: 16pt
- Large: 24pt
- Extra Large: 32pt

### Standard Padding
```swift
.padding(.horizontal, 20)  // Content margins
.padding(.bottom, 100)     // Tab bar clearance
```

## Navigation

### NavigationStack (iOS 16+)
```swift
NavigationStack {
    List(items) { item in
        NavigationLink(value: item) {
            ItemRow(item: item)
        }
    }
    .navigationDestination(for: Item.self) { item in
        ItemDetail(item: item)
    }
}
```

### NavigationSplitView (iPad)
```swift
NavigationSplitView {
    Sidebar()
} detail: {
    DetailView()
}
```

## Common Patterns

### Conditional Content
```swift
// Prefer if/else for exclusive content
if isLoading {
    ProgressView()
} else {
    ContentView()
}

// Use opacity for overlays
ContentView()
    .opacity(isLoading ? 0.5 : 1)
```

### Safe Area Handling
```swift
// Full-bleed backgrounds
.ignoresSafeArea(edges: .top)

// Content spacing
.safeAreaInset(edge: .bottom) {
    BottomBar()
}
```

### Sheet Presentation
```swift
.sheet(isPresented: $showingDetail) {
    DetailView()
        .presentationDetents([.medium, .large])
}
```

### Animation
```swift
// Always specify value parameter
.animation(.spring(), value: isExpanded)

// withAnimation for imperative
withAnimation(.easeInOut) {
    isExpanded.toggle()
}
```

## ViewModel Pattern

```swift
@MainActor
class FeatureViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var error: Error?

    func loadItems() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await fetchItems()
        } catch {
            self.error = error
        }
    }
}
```

## Avoid These

```swift
// DON'T: Force unwrap in views
Text(item.title!)  // Crash risk

// DON'T: Heavy computation in body
var body: some View {
    let sorted = items.sorted()  // Move to ViewModel
}

// DON'T: Animation without value
.animation(.spring())  // Deprecated

// DON'T: @StateObject for singletons
@StateObject var settings = AppSettings.shared  // Wrong ownership

// DON'T: Inline closures that capture self strongly
Timer.scheduledTimer { self.tick() }  // Leak risk
```

## Performance Tips

1. Use `LazyVStack` / `LazyHStack` for long lists
2. Use `@ViewBuilder` for conditional views
3. Avoid expensive work in `body`
4. Use `.drawingGroup()` for complex graphics
5. Profile with Instruments Time Profiler
