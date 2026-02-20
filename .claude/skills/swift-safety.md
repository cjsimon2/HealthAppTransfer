# Swift Safety Patterns

## Optional Handling

### Safe Unwrapping
```swift
// Guard for early exit
guard let value = optionalValue else {
    return
}

// If-let for scoped access
if let value = optionalValue {
    use(value)
}

// Nil coalescing for defaults
let value = optionalValue ?? defaultValue

// Optional chaining
let count = optionalArray?.count
```

### Avoid Force Unwrapping
```swift
// DANGEROUS
let value = optionalValue!  // Crash if nil

// SAFE
guard let value = optionalValue else {
    // Handle nil case
    return
}
```

### Optional Map/FlatMap
```swift
// Transform optional without unwrapping
let uppercased = optionalString.map { $0.uppercased() }

// Chain optionals
let nested = optionalOuter.flatMap { $0.optionalInner }
```

## Error Handling

### Do-Try-Catch
```swift
do {
    let data = try fetchData()
    process(data)
} catch NetworkError.timeout {
    showTimeoutError()
} catch {
    showGenericError(error)
}
```

### Throwing Functions
```swift
func fetchData() throws -> Data {
    guard let url = URL(string: urlString) else {
        throw FetchError.invalidURL
    }
    return try Data(contentsOf: url)
}
```

### Result Type
```swift
func fetchData() -> Result<Data, Error> {
    do {
        let data = try performFetch()
        return .success(data)
    } catch {
        return .failure(error)
    }
}

// Usage
switch fetchData() {
case .success(let data):
    process(data)
case .failure(let error):
    handle(error)
}
```

### Async/Await Error Handling
```swift
func loadData() async throws -> Data {
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw NetworkError.badResponse
    }
    return data
}

// Usage
Task {
    do {
        let data = try await loadData()
    } catch {
        // Handle error
    }
}
```

## Memory Safety

### Weak References
```swift
// Closures that may outlive self
publisher.sink { [weak self] value in
    self?.handle(value)
}

// Delegates
weak var delegate: MyDelegate?

// Timers
Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
    self?.tick()
}
```

### Unowned References
```swift
// Only when lifetime is guaranteed
class Parent {
    var child: Child?

    init() {
        child = Child(parent: self)
    }
}

class Child {
    unowned let parent: Parent  // Parent always outlives Child

    init(parent: Parent) {
        self.parent = parent
    }
}
```

## Thread Safety

### @MainActor
```swift
@MainActor
class ViewModel: ObservableObject {
    @Published var items: [Item] = []

    func updateItems(_ newItems: [Item]) {
        items = newItems  // Safe: on main thread
    }
}
```

### Actor Isolation
```swift
actor DataStore {
    private var cache: [String: Data] = [:]

    func getData(for key: String) -> Data? {
        cache[key]
    }

    func setData(_ data: Data, for key: String) {
        cache[key] = data
    }
}

// Usage
await dataStore.setData(data, for: "key")
```

### Task and MainActor
```swift
Task { @MainActor in
    // Runs on main thread
    self.updateUI()
}

// Or from async context
await MainActor.run {
    self.updateUI()
}
```

## Collection Safety

### Safe Array Access
```swift
// DANGEROUS
let item = array[index]  // Crash if out of bounds

// SAFE
extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

let item = array[safe: index]
```

### First/Last
```swift
// Safe - returns optional
let first = array.first
let last = array.last

// Dangerous
let first = array[0]  // Crash if empty
```

## Type Safety

### Codable Safety
```swift
struct User: Codable {
    let id: Int
    let name: String
    let email: String?  // Optional for backwards compatibility

    // Handle missing keys
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown"
        email = try container.decodeIfPresent(String.self, forKey: .email)
    }
}
```

### Enum with Unknown Cases
```swift
enum Status: String, Codable {
    case active
    case inactive
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = Status(rawValue: value) ?? .unknown
    }
}
```

## Assertions and Preconditions

```swift
// Debug-only check
assert(index >= 0, "Index must be non-negative")

// Always checked (use sparingly)
precondition(array.count > 0, "Array must not be empty")

// Fatal error for impossible states
guard let value = impossibleToBeNil else {
    fatalError("This should never happen")
}
```
