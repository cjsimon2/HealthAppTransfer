# SwiftUI Performance Optimization

## View Rendering Performance

### Avoid Expensive Body Computations
```swift
// SLOW - Computed in body
var body: some View {
    let sorted = items.sorted { $0.date > $1.date }  // Called on every render
    List(sorted) { item in ItemRow(item: item) }
}

// FAST - Computed in ViewModel
@MainActor
class ItemsViewModel: ObservableObject {
    @Published private(set) var sortedItems: [Item] = []

    func updateItems(_ items: [Item]) {
        sortedItems = items.sorted { $0.date > $1.date }
    }
}
```

### Use Lazy Containers
```swift
// SLOW - All views created immediately
ScrollView {
    VStack {
        ForEach(items) { item in
            ExpensiveView(item: item)
        }
    }
}

// FAST - Views created on demand
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ExpensiveView(item: item)
        }
    }
}
```

### Equatable Views
```swift
// Enable view comparison to skip unnecessary updates
struct ItemRow: View, Equatable {
    let item: Item

    static func == (lhs: ItemRow, rhs: ItemRow) -> Bool {
        lhs.item.id == rhs.item.id &&
        lhs.item.title == rhs.item.title
    }

    var body: some View {
        Text(item.title)
    }
}

// Usage
ForEach(items) { item in
    ItemRow(item: item)
        .equatable()  // Use Equatable comparison
}
```

## State Management Performance

### Minimize Published Properties
```swift
// SLOW - Every property change triggers view update
class ViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var filterOption = FilterOption.all
}

// FAST - Group related state
class ViewModel: ObservableObject {
    struct ViewState: Equatable {
        var items: [Item] = []
        var isLoading = false
    }

    @Published var state = ViewState()
    @Published var searchText = ""  // Separate for text field binding
}
```

### Use ObjectWillChange Sparingly
```swift
class ViewModel: ObservableObject {
    private var _items: [Item] = []

    var items: [Item] {
        get { _items }
        set {
            // Only notify if actually changed
            if _items != newValue {
                objectWillChange.send()
                _items = newValue
            }
        }
    }
}
```

### Derived State with Computed Properties
```swift
class ViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var searchText = ""

    // Computed - no extra storage, no extra notifications
    var filteredItems: [Item] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
}
```

## List Performance

### Stable Identifiers
```swift
// SLOW - Unstable identifiers cause full redraws
ForEach(items.indices, id: \.self) { index in
    ItemRow(item: items[index])
}

// FAST - Stable identifiers enable efficient diffing
ForEach(items, id: \.id) { item in
    ItemRow(item: item)
}
```

### Cell Recycling
```swift
// Enable cell reuse in Lists
List(items) { item in
    ItemRow(item: item)
}
.listStyle(.plain)  // Plain style has better recycling
```

### Prefetching
```swift
struct ItemList: View {
    @StateObject var viewModel = ItemsViewModel()

    var body: some View {
        List(viewModel.items) { item in
            ItemRow(item: item)
                .onAppear {
                    // Prefetch when near end
                    if item == viewModel.items.last {
                        Task { await viewModel.loadMore() }
                    }
                }
        }
    }
}
```

## Image Performance

### Async Image Loading
```swift
// Use AsyncImage for remote images
AsyncImage(url: imageURL) { phase in
    switch phase {
    case .empty:
        ProgressView()
    case .success(let image):
        image.resizable().aspectRatio(contentMode: .fit)
    case .failure:
        Image(systemName: "photo")
    @unknown default:
        EmptyView()
    }
}
.frame(width: 100, height: 100)
```

### Image Caching
```swift
// Use a caching image loader
class ImageCache {
    static let shared = NSCache<NSString, UIImage>()

    static func image(for url: URL) async -> UIImage? {
        let key = url.absoluteString as NSString

        if let cached = shared.object(forKey: key) {
            return cached
        }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data) else {
            return nil
        }

        shared.setObject(image, forKey: key)
        return image
    }
}
```

### Downsampling Large Images
```swift
extension UIImage {
    static func downsample(url: URL, to size: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions) else {
            return nil
        }

        let maxDimension = max(size.width, size.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ] as CFDictionary

        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }

        return UIImage(cgImage: downsampledImage)
    }
}
```

## Animation Performance

### Use drawingGroup for Complex Graphics
```swift
// Flatten complex view hierarchies for GPU rendering
ZStack {
    ForEach(0..<100) { i in
        Circle()
            .fill(Color.blue.opacity(0.1))
            .frame(width: CGFloat(i * 2))
    }
}
.drawingGroup()  // Render as single layer
```

### Animate Only What's Needed
```swift
// SLOW - Animates entire view
VStack {
    ExpensiveView()
    Text("Count: \(count)")
}
.animation(.default, value: count)

// FAST - Animate only the changing part
VStack {
    ExpensiveView()
    Text("Count: \(count)")
        .animation(.default, value: count)
}
```

## Profiling Tools

### Instruments
- **Time Profiler**: Find slow code paths
- **SwiftUI View Body**: Track view body evaluations
- **Core Animation**: GPU rendering issues
- **Allocations**: Memory usage patterns

### Debug Options
```swift
// In DEBUG builds
#if DEBUG
extension View {
    func debugPrint(_ value: String) -> some View {
        print("View update: \(value)")
        return self
    }
}
#endif
```

### Performance Metrics
```swift
// Measure view rendering time
let start = CFAbsoluteTimeGetCurrent()
// ... render view
let elapsed = CFAbsoluteTimeGetCurrent() - start
print("Render time: \(elapsed * 1000)ms")
```
