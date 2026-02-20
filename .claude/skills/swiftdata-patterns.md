# SwiftData Patterns

## Model Definition

### Basic Model
```swift
import SwiftData

@Model
final class Item {
    var title: String
    var createdAt: Date
    var isCompleted: Bool

    // Relationships
    @Relationship(deleteRule: .cascade)
    var subtasks: [Subtask]?

    @Relationship(inverse: \Category.items)
    var category: Category?

    init(title: String) {
        self.title = title
        self.createdAt = Date()
        self.isCompleted = false
    }
}

@Model
final class Category {
    var name: String
    var items: [Item]?

    init(name: String) {
        self.name = name
    }
}
```

### Transient Properties
```swift
@Model
final class Task {
    var title: String
    var dueDate: Date?

    // Not persisted
    @Transient
    var isOverdue: Bool {
        guard let dueDate else { return false }
        return dueDate < Date()
    }

    init(title: String) {
        self.title = title
    }
}
```

### Unique Constraints
```swift
@Model
final class User {
    @Attribute(.unique)
    var email: String

    var name: String

    init(email: String, name: String) {
        self.email = email
        self.name = name
    }
}
```

## Container Setup

### Basic Setup
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Item.self, Category.self])
    }
}
```

### Custom Configuration
```swift
@main
struct MyApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Item.self, Category.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
```

### In-Memory for Testing
```swift
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(for: Item.self, inMemory: true)
    }
}
```

## Queries

### Basic Query
```swift
struct ItemListView: View {
    @Query var items: [Item]

    var body: some View {
        List(items) { item in
            Text(item.title)
        }
    }
}
```

### Filtered Query
```swift
struct ActiveItemsView: View {
    @Query(filter: #Predicate<Item> { !$0.isCompleted })
    var activeItems: [Item]

    var body: some View {
        List(activeItems) { item in
            Text(item.title)
        }
    }
}
```

### Sorted Query
```swift
struct SortedItemsView: View {
    @Query(sort: \Item.createdAt, order: .reverse)
    var items: [Item]

    // Multiple sort descriptors
    @Query(sort: [
        SortDescriptor(\Item.isCompleted),
        SortDescriptor(\Item.createdAt, order: .reverse)
    ])
    var sortedItems: [Item]
}
```

### Dynamic Queries
```swift
struct SearchableItemsView: View {
    @State private var searchText = ""

    var body: some View {
        ItemList(searchText: searchText)
            .searchable(text: $searchText)
    }
}

struct ItemList: View {
    @Query private var items: [Item]

    init(searchText: String) {
        let predicate: Predicate<Item>
        if searchText.isEmpty {
            predicate = #Predicate { _ in true }
        } else {
            predicate = #Predicate<Item> { item in
                item.title.localizedStandardContains(searchText)
            }
        }
        _items = Query(filter: predicate, sort: \Item.createdAt)
    }

    var body: some View {
        List(items) { item in
            Text(item.title)
        }
    }
}
```

## CRUD Operations

### Create
```swift
struct AddItemView: View {
    @Environment(\.modelContext) private var context
    @State private var title = ""

    var body: some View {
        Form {
            TextField("Title", text: $title)
            Button("Add") {
                let item = Item(title: title)
                context.insert(item)
                title = ""
            }
        }
    }
}
```

### Update
```swift
struct ItemDetailView: View {
    @Bindable var item: Item

    var body: some View {
        Form {
            TextField("Title", text: $item.title)
            Toggle("Completed", isOn: $item.isCompleted)
        }
    }
}
```

### Delete
```swift
struct ItemListView: View {
    @Environment(\.modelContext) private var context
    @Query var items: [Item]

    var body: some View {
        List {
            ForEach(items) { item in
                Text(item.title)
            }
            .onDelete(perform: deleteItems)
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            context.delete(items[index])
        }
    }
}
```

### Batch Operations
```swift
func deleteAllCompleted(context: ModelContext) throws {
    let predicate = #Predicate<Item> { $0.isCompleted }
    try context.delete(model: Item.self, where: predicate)
}
```

## Relationships

### One-to-Many
```swift
@Model
final class Project {
    var name: String

    @Relationship(deleteRule: .cascade)
    var tasks: [Task]?

    init(name: String) {
        self.name = name
    }
}

@Model
final class Task {
    var title: String
    var project: Project?

    init(title: String) {
        self.title = title
    }
}

// Adding related items
let project = Project(name: "My Project")
let task = Task(title: "First Task")
task.project = project
// Or
project.tasks?.append(task)
```

### Many-to-Many
```swift
@Model
final class Tag {
    var name: String
    var items: [Item]?

    init(name: String) {
        self.name = name
    }
}

@Model
final class Item {
    var title: String
    var tags: [Tag]?

    init(title: String) {
        self.title = title
    }
}
```

## Migration

### Schema Versioning
```swift
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Item.self]
    }

    @Model
    final class Item {
        var title: String
        init(title: String) {
            self.title = title
        }
    }
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Item.self]
    }

    @Model
    final class Item {
        var title: String
        var priority: Int  // New property

        init(title: String, priority: Int = 0) {
            self.title = title
            self.priority = priority
        }
    }
}
```

### Migration Plan
```swift
enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}

// Use in container
let container = try ModelContainer(
    for: SchemaV2.Item.self,
    migrationPlan: MigrationPlan.self
)
```

## Best Practices

1. **Use @Query for reactive data** - Automatically updates when data changes
2. **Keep models simple** - Avoid complex computed properties in models
3. **Use relationships** - Let SwiftData handle foreign keys
4. **Delete rules** - Set appropriate cascade/nullify rules
5. **Batch operations** - Use batch delete for large datasets
6. **In-memory for previews** - Speed up SwiftUI previews
7. **Handle errors** - Wrap context operations in do-catch
