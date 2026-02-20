# MVVM Patterns for SwiftUI

## Basic ViewModel Structure

### Standard ViewModel
```swift
@MainActor
class FeatureViewModel: ObservableObject {
    // MARK: - Published State
    @Published private(set) var items: [Item] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    // MARK: - Dependencies
    private let repository: ItemRepository

    // MARK: - Init
    init(repository: ItemRepository = ItemRepository()) {
        self.repository = repository
    }

    // MARK: - Actions
    func loadItems() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await repository.fetchItems()
            error = nil
        } catch {
            self.error = error
        }
    }

    func addItem(_ item: Item) async {
        do {
            try await repository.save(item)
            items.append(item)
        } catch {
            self.error = error
        }
    }
}
```

### View Integration
```swift
struct FeatureView: View {
    @StateObject private var viewModel = FeatureViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                ErrorView(error: error, retry: { Task { await viewModel.loadItems() } })
            } else {
                ItemList(items: viewModel.items)
            }
        }
        .task { await viewModel.loadItems() }
    }
}
```

## Dependency Injection

### Protocol-Based Dependencies
```swift
protocol ItemRepositoryProtocol {
    func fetchItems() async throws -> [Item]
    func save(_ item: Item) async throws
}

class ItemRepository: ItemRepositoryProtocol {
    func fetchItems() async throws -> [Item] {
        // Real implementation
    }

    func save(_ item: Item) async throws {
        // Real implementation
    }
}

// For testing
class MockItemRepository: ItemRepositoryProtocol {
    var itemsToReturn: [Item] = []

    func fetchItems() async throws -> [Item] {
        return itemsToReturn
    }

    func save(_ item: Item) async throws {
        itemsToReturn.append(item)
    }
}
```

### Environment-Based Injection
```swift
// Define environment key
private struct RepositoryKey: EnvironmentKey {
    static let defaultValue: ItemRepositoryProtocol = ItemRepository()
}

extension EnvironmentValues {
    var itemRepository: ItemRepositoryProtocol {
        get { self[RepositoryKey.self] }
        set { self[RepositoryKey.self] = newValue }
    }
}

// Use in view
struct FeatureView: View {
    @Environment(\.itemRepository) private var repository
    @StateObject private var viewModel: FeatureViewModel

    init() {
        // Note: Can't use @Environment in init, use alternative pattern
    }
}
```

### Factory Pattern
```swift
class ViewModelFactory {
    static let shared = ViewModelFactory()

    private let repository: ItemRepositoryProtocol

    init(repository: ItemRepositoryProtocol = ItemRepository()) {
        self.repository = repository
    }

    func makeFeatureViewModel() -> FeatureViewModel {
        FeatureViewModel(repository: repository)
    }
}
```

## State Management Patterns

### View State Enum
```swift
enum ViewState<T> {
    case idle
    case loading
    case loaded(T)
    case error(Error)
}

@MainActor
class ItemsViewModel: ObservableObject {
    @Published private(set) var state: ViewState<[Item]> = .idle

    func load() async {
        state = .loading
        do {
            let items = try await repository.fetchItems()
            state = .loaded(items)
        } catch {
            state = .error(error)
        }
    }
}

// View usage
struct ItemsView: View {
    @StateObject private var viewModel = ItemsViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                EmptyView()
            case .loading:
                ProgressView()
            case .loaded(let items):
                ItemList(items: items)
            case .error(let error):
                ErrorView(error: error)
            }
        }
        .task { await viewModel.load() }
    }
}
```

### Grouped State
```swift
@MainActor
class FormViewModel: ObservableObject {
    struct FormState: Equatable {
        var name = ""
        var email = ""
        var isValid: Bool {
            !name.isEmpty && email.contains("@")
        }
    }

    struct UIState: Equatable {
        var isSubmitting = false
        var showingConfirmation = false
        var errorMessage: String?
    }

    @Published var form = FormState()
    @Published private(set) var ui = UIState()

    func submit() async {
        guard form.isValid else { return }

        ui.isSubmitting = true
        defer { ui.isSubmitting = false }

        do {
            try await service.submit(form)
            ui.showingConfirmation = true
        } catch {
            ui.errorMessage = error.localizedDescription
        }
    }
}
```

## Navigation Patterns

### Coordinator ViewModel
```swift
@MainActor
class NavigationViewModel: ObservableObject {
    @Published var path = NavigationPath()
    @Published var presentedSheet: Sheet?

    enum Sheet: Identifiable {
        case addItem
        case editItem(Item)
        case settings

        var id: String {
            switch self {
            case .addItem: return "addItem"
            case .editItem(let item): return "edit-\(item.id)"
            case .settings: return "settings"
            }
        }
    }

    func navigateToDetail(_ item: Item) {
        path.append(item)
    }

    func presentAddItem() {
        presentedSheet = .addItem
    }

    func dismissSheet() {
        presentedSheet = nil
    }
}
```

### Navigation View
```swift
struct RootView: View {
    @StateObject private var navigation = NavigationViewModel()

    var body: some View {
        NavigationStack(path: $navigation.path) {
            ItemListView()
                .navigationDestination(for: Item.self) { item in
                    ItemDetailView(item: item)
                }
        }
        .sheet(item: $navigation.presentedSheet) { sheet in
            switch sheet {
            case .addItem:
                AddItemView()
            case .editItem(let item):
                EditItemView(item: item)
            case .settings:
                SettingsView()
            }
        }
        .environmentObject(navigation)
    }
}
```

## Child ViewModels

### Parent-Child Communication
```swift
@MainActor
class ParentViewModel: ObservableObject {
    @Published var items: [Item] = []

    func makeChildViewModel(for item: Item) -> ChildViewModel {
        ChildViewModel(
            item: item,
            onSave: { [weak self] updatedItem in
                self?.updateItem(updatedItem)
            },
            onDelete: { [weak self] in
                self?.deleteItem(item)
            }
        )
    }

    private func updateItem(_ item: Item) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        }
    }

    private func deleteItem(_ item: Item) {
        items.removeAll { $0.id == item.id }
    }
}

@MainActor
class ChildViewModel: ObservableObject {
    @Published var item: Item

    private let onSave: (Item) -> Void
    private let onDelete: () -> Void

    init(item: Item, onSave: @escaping (Item) -> Void, onDelete: @escaping () -> Void) {
        self.item = item
        self.onSave = onSave
        self.onDelete = onDelete
    }

    func save() {
        onSave(item)
    }

    func delete() {
        onDelete()
    }
}
```

## Testing ViewModels

### Unit Tests
```swift
@MainActor
final class FeatureViewModelTests: XCTestCase {
    var sut: FeatureViewModel!
    var mockRepository: MockItemRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockItemRepository()
        sut = FeatureViewModel(repository: mockRepository)
    }

    func testLoadItems_Success() async {
        // Given
        let expectedItems = [Item(id: "1", title: "Test")]
        mockRepository.itemsToReturn = expectedItems

        // When
        await sut.loadItems()

        // Then
        XCTAssertEqual(sut.items, expectedItems)
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadItems_Error() async {
        // Given
        mockRepository.shouldThrowError = true

        // When
        await sut.loadItems()

        // Then
        XCTAssertTrue(sut.items.isEmpty)
        XCTAssertNotNil(sut.error)
    }
}
```

## Best Practices

1. **Mark ViewModels with @MainActor** - Ensures UI updates on main thread
2. **Use private(set) for Published properties** - Prevent external mutation
3. **Inject dependencies** - Enable testing and flexibility
4. **Keep ViewModels view-agnostic** - No UIKit/SwiftUI imports
5. **Use async/await** - Modern concurrency over Combine for simple cases
6. **Group related state** - Reduce number of @Published properties
7. **Prefer computed properties** - For derived state that doesn't need caching
