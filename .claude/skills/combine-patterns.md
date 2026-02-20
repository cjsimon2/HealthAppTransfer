# Combine Patterns for SwiftUI

## Publishers and Subscribers

### Basic Publisher Usage
```swift
import Combine

class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var results: [SearchResult] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupSearchPipeline()
    }

    private func setupSearchPipeline() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .filter { !$0.isEmpty }
            .sink { [weak self] query in
                Task { await self?.search(query) }
            }
            .store(in: &cancellables)
    }

    private func search(_ query: String) async {
        // Perform search
    }
}
```

### Custom Publishers
```swift
extension NotificationCenter {
    var keyboardPublisher: AnyPublisher<CGFloat, Never> {
        Publishers.Merge(
            publisher(for: UIResponder.keyboardWillShowNotification)
                .map { notification in
                    (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
                },
            publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in CGFloat(0) }
        )
        .eraseToAnyPublisher()
    }
}
```

## Common Operators

### Transformation
```swift
// Map - Transform values
$text
    .map { $0.uppercased() }
    .assign(to: &$uppercasedText)

// CompactMap - Transform and filter nil
$optionalValue
    .compactMap { $0 }
    .sink { value in /* guaranteed non-nil */ }
    .store(in: &cancellables)

// FlatMap - Transform to new publisher
$userId
    .flatMap { [weak self] id -> AnyPublisher<User, Never> in
        self?.userService.fetchUser(id: id) ?? Empty().eraseToAnyPublisher()
    }
    .sink { user in /* handle user */ }
    .store(in: &cancellables)
```

### Filtering
```swift
// Filter - Keep matching values
$items
    .filter { !$0.isEmpty }
    .sink { items in /* non-empty items */ }
    .store(in: &cancellables)

// RemoveDuplicates - Skip consecutive duplicates
$searchText
    .removeDuplicates()
    .sink { text in /* only when changed */ }
    .store(in: &cancellables)

// First - Take only first value
$state
    .first { $0 == .ready }
    .sink { _ in /* triggered once when ready */ }
    .store(in: &cancellables)
```

### Timing
```swift
// Debounce - Wait for pause in values
$searchText
    .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
    .sink { text in /* after 300ms pause */ }
    .store(in: &cancellables)

// Throttle - Limit rate of values
$scrollOffset
    .throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: true)
    .sink { offset in /* max 10 times per second */ }
    .store(in: &cancellables)

// Delay - Delay delivery
$notification
    .delay(for: .seconds(2), scheduler: RunLoop.main)
    .sink { notification in /* 2 seconds later */ }
    .store(in: &cancellables)
```

### Combining
```swift
// CombineLatest - Combine latest from multiple publishers
Publishers.CombineLatest($username, $password)
    .map { username, password in
        !username.isEmpty && password.count >= 8
    }
    .assign(to: &$isFormValid)

// Merge - Merge multiple publishers of same type
Publishers.Merge(saveButton.publisher, submitButton.publisher)
    .sink { _ in /* either button tapped */ }
    .store(in: &cancellables)

// Zip - Pair values one-to-one
Publishers.Zip($firstName, $lastName)
    .map { "\($0) \($1)" }
    .assign(to: &$fullName)
```

## Error Handling

### Catch and Replace
```swift
urlSession.dataTaskPublisher(for: url)
    .map(\.data)
    .decode(type: User.self, decoder: JSONDecoder())
    .catch { error -> Just<User> in
        print("Error: \(error)")
        return Just(User.placeholder)
    }
    .receive(on: DispatchQueue.main)
    .assign(to: &$user)
```

### Retry
```swift
urlSession.dataTaskPublisher(for: url)
    .retry(3)  // Retry up to 3 times
    .catch { _ in Empty<Data, Never>() }
    .sink { data in /* handle data */ }
    .store(in: &cancellables)
```

### MapError
```swift
enum AppError: Error {
    case network(Error)
    case decoding(Error)
}

urlSession.dataTaskPublisher(for: url)
    .mapError { AppError.network($0) }
    .tryMap { data, response -> Data in
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AppError.network(URLError(.badServerResponse))
        }
        return data
    }
    .decode(type: User.self, decoder: JSONDecoder())
    .mapError { AppError.decoding($0) }
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                /* handle typed error */
            }
        },
        receiveValue: { user in /* handle user */ }
    )
    .store(in: &cancellables)
```

## Subjects

### PassthroughSubject
```swift
class EventBus {
    static let shared = EventBus()

    let userLoggedIn = PassthroughSubject<User, Never>()
    let userLoggedOut = PassthroughSubject<Void, Never>()

    func login(_ user: User) {
        userLoggedIn.send(user)
    }

    func logout() {
        userLoggedOut.send()
    }
}

// Subscribe
EventBus.shared.userLoggedIn
    .sink { user in /* handle login */ }
    .store(in: &cancellables)
```

### CurrentValueSubject
```swift
class SettingsService {
    let theme = CurrentValueSubject<Theme, Never>(.system)

    var currentTheme: Theme {
        theme.value
    }

    func setTheme(_ newTheme: Theme) {
        theme.send(newTheme)
    }
}
```

## SwiftUI Integration

### OnReceive
```swift
struct TimerView: View {
    @State private var count = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text("Count: \(count)")
            .onReceive(timer) { _ in
                count += 1
            }
    }
}
```

### Binding from Publisher
```swift
class FormViewModel: ObservableObject {
    @Published var email = ""
    @Published private(set) var isEmailValid = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        $email
            .map { $0.contains("@") && $0.contains(".") }
            .assign(to: &$isEmailValid)
    }
}
```

## Memory Management

### Weak Self in Closures
```swift
$searchText
    .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
    .sink { [weak self] text in
        self?.performSearch(text)
    }
    .store(in: &cancellables)
```

### Cancellation
```swift
class ViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private var searchCancellable: AnyCancellable?

    func search(_ query: String) {
        // Cancel previous search
        searchCancellable?.cancel()

        searchCancellable = searchService.search(query)
            .sink { [weak self] results in
                self?.results = results
            }
    }

    deinit {
        cancellables.forEach { $0.cancel() }
    }
}
```

## When to Use Combine vs async/await

### Use Combine For:
- Reactive UI bindings
- Debouncing/throttling
- Combining multiple streams
- Complex event processing

### Use async/await For:
- Simple one-shot operations
- Sequential async code
- Error handling with try/catch
- Structured concurrency

### Bridging
```swift
// Combine to async
extension Publisher {
    func firstValue() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                    }
                )
        }
    }
}

// async to Combine
func fetchUserPublisher() -> AnyPublisher<User, Error> {
    Deferred {
        Future { promise in
            Task {
                do {
                    let user = try await fetchUser()
                    promise(.success(user))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
    .eraseToAnyPublisher()
}
```
