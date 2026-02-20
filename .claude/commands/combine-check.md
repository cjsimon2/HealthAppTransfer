# Combine Usage Check Command

Review Combine framework usage for correctness and memory safety.

## Target
$ARGUMENTS

## Combine Patterns

### Basic Publisher Subscription
```swift
class MyViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    init() {
        somePublisher
            .sink { [weak self] value in
                self?.handleValue(value)
            }
            .store(in: &cancellables)
    }
}
```

## Review Checklist

### Memory Safety
- [ ] All sinks use `[weak self]`
- [ ] Cancellables stored in Set
- [ ] No retain cycles in chains
- [ ] Subscriptions properly cancelled

### Error Handling
- [ ] `sink(receiveCompletion:receiveValue:)` used when errors possible
- [ ] Errors handled appropriately
- [ ] Retry logic where appropriate

### Threading
- [ ] `receive(on: DispatchQueue.main)` for UI updates
- [ ] Background work on appropriate queue
- [ ] No main thread blocking

## Common Issues

### 1. Missing [weak self]
```swift
// LEAK - Strong reference cycle
publisher.sink { value in
    self.process(value)
}.store(in: &cancellables)

// FIXED
publisher.sink { [weak self] value in
    self?.process(value)
}.store(in: &cancellables)
```

### 2. Subscription Not Stored
```swift
// BUG - Immediately cancelled
publisher.sink { value in
    // Never receives values
}

// FIXED
publisher.sink { value in
    // Receives values
}.store(in: &cancellables)
```

### 3. Main Thread UI Updates
```swift
// BUG - May crash if not on main thread
networkPublisher
    .sink { [weak self] data in
        self?.items = data  // @Published update off main thread
    }
    .store(in: &cancellables)

// FIXED
networkPublisher
    .receive(on: DispatchQueue.main)
    .sink { [weak self] data in
        self?.items = data
    }
    .store(in: &cancellables)
```

### 4. Error Not Handled
```swift
// BUG - Errors silently ignored
failablePublisher
    .sink { value in
        // What about errors?
    }

// FIXED
failablePublisher
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                // Handle error
            }
        },
        receiveValue: { value in
            // Handle value
        }
    )
```

## Common Operators

### Transformation
```swift
.map { $0.property }
.compactMap { $0 }  // Filter nil
.flatMap { nestedPublisher }
```

### Filtering
```swift
.filter { $0.isValid }
.removeDuplicates()
.debounce(for: .seconds(0.5), scheduler: RunLoop.main)
```

### Combining
```swift
Publishers.CombineLatest(pub1, pub2)
Publishers.Merge(pub1, pub2)
pub1.zip(pub2)
```

### Error Handling
```swift
.catch { error in Just(fallbackValue) }
.retry(3)
.replaceError(with: defaultValue)
```

## Output

1. Combine usage summary
2. Memory safety issues
3. Threading concerns
4. Recommended fixes
