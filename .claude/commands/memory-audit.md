# Memory Audit Command

Find potential memory leaks and retention issues.

## Target
$ARGUMENTS

## Memory Issue Categories

### 1. Retain Cycles in Closures

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

### 2. Delegate Patterns

```swift
// LEAK - Strong delegate
class Manager {
    var delegate: SomeDelegate?
}

// FIXED
class Manager {
    weak var delegate: SomeDelegate?
}
```

### 3. Timer References

```swift
// LEAK - Timer holds strong reference
timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
    self.tick()
}

// FIXED
timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
    self?.tick()
}
```

### 4. NotificationCenter Observers

```swift
// Store observer reference for cleanup
private var observer: Any?

init() {
    observer = NotificationCenter.default.addObserver(
        forName: .someNotification,
        object: nil,
        queue: .main
    ) { [weak self] _ in
        self?.handleNotification()
    }
}

deinit {
    if let observer = observer {
        NotificationCenter.default.removeObserver(observer)
    }
}
```

### 5. SwiftUI Specific

```swift
// Verify correct property wrapper usage
@StateObject var viewModel = ViewModel()  // View owns
@ObservedObject var settings = Shared.shared  // External owns

// @StateObject for owned objects only
```

## Audit Checklist

### ViewModels
- [ ] All Combine sinks use `[weak self]`
- [ ] Cancellables set exists and is used
- [ ] No strong delegate references
- [ ] Timer references use weak self

### Managers/Services
- [ ] Singleton uses `static let` (not `static var`)
- [ ] NotificationCenter observers stored and removed
- [ ] No circular manager dependencies

### Views
- [ ] Correct state property wrappers
- [ ] No closures capturing self strongly
- [ ] Verify deinit called when dismissed

## Detection Methods

### 1. Debug Logging
```swift
class MyClass {
    init() { print("MyClass init") }
    deinit { print("MyClass deinit") }  // Should see this
}
```

### 2. Xcode Memory Graph
```
Debug > Debug Workflow > View Memory Graph Debugger
```

### 3. Instruments - Leaks
```
Product > Profile > Leaks
```

### 4. Search Patterns
```
// Closures without [weak self]
\.sink\s*\{\s*[^[]*self\.

// Strong delegates
var delegate:.*(?!weak)

// Timer without weak
Timer.*\{[^[]*self\.
```

## Manager Cleanup Pattern

```swift
@MainActor
class MyManager: ObservableObject {
    private var timer: Timer?
    private var observers: [Any] = []

    init() {
        setupTimer()
        setupObservers()
    }

    deinit {
        timer?.invalidate()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.doWork()
            }
        }
    }

    private func setupObservers() {
        let observer = NotificationCenter.default.addObserver(
            forName: .someNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleNotification()
        }
        observers.append(observer)
    }
}
```

## Output Format

### Potential Leaks Found

| Type | File | Line | Issue | Severity |
|------|------|------|-------|----------|
| Closure | ViewModel.swift | 45 | Missing [weak self] | High |
| Delegate | Manager.swift | 12 | Not weak | High |
| Timer | Service.swift | 89 | Strong capture | High |

### Recommendations

For each issue:
1. **Problem:** What causes the leak
2. **Impact:** Memory growth, performance
3. **Fix:** Code change needed
4. **Verification:** How to confirm fix
