# SwiftData Model Review Command

Review SwiftData models and queries.

## Target
$ARGUMENTS

## SwiftData Best Practices

### Model Definition

#### Correct Model Pattern
```swift
@Model
final class TaskItem {
    // UUID with default - safe for sync
    var id: UUID = UUID()

    // Strings with defaults
    var title: String = ""
    var notes: String = ""

    // Optionals are fine
    var dueDate: Date?

    // Booleans with defaults
    var isCompleted: Bool = false

    // Dates with defaults
    var createdDate: Date = Date()

    // Arrays stored as JSON Data (CloudKit compatibility)
    var subtasksData: Data?

    // Computed property for array access
    var subtasks: [Subtask] {
        get {
            guard let data = subtasksData else { return [] }
            return (try? JSONDecoder().decode([Subtask].self, from: data)) ?? []
        }
        set {
            subtasksData = try? JSONEncoder().encode(newValue)
        }
    }
}
```

### Review Checklist

#### Model Definition
- [ ] All properties have default values
- [ ] Arrays stored as JSON-encoded Data
- [ ] IDs are UUIDs, never modified after creation
- [ ] Codable types handle missing keys gracefully
- [ ] Relationships defined correctly

#### CloudKit Compatibility (if using)
- [ ] No unsupported types
- [ ] Relationships are to-one or encoded to-many
- [ ] Model changes are additive (new fields have defaults)
- [ ] No required relationships without defaults

#### Query Safety
- [ ] Queries use predicates efficiently
- [ ] Large result sets paginated
- [ ] Sorting applied at query level
- [ ] No N+1 query patterns

### Common Issues

#### 1. Missing Default Value
```swift
// WRONG - Will crash on existing data
@Model
final class MyModel {
    var newProperty: String  // No default!
}

// RIGHT
@Model
final class MyModel {
    var newProperty: String = ""
}
```

#### 2. Direct Array Storage
```swift
// WRONG - CloudKit sync issues
@Model
final class MyModel {
    var items: [String] = []
}

// RIGHT - JSON encode
@Model
final class MyModel {
    var itemsData: Data?

    var items: [String] {
        get { /* decode */ }
        set { /* encode */ }
    }
}
```

#### 3. Modifying IDs
```swift
// WRONG - Breaks sync
item.id = UUID()  // Never do this!

// RIGHT - IDs are immutable
let newItem = TaskItem()  // Gets new UUID
```

#### 4. Enum Storage
```swift
// Store enum as raw value
var statusRaw: String = "pending"

var status: Status {
    get { Status(rawValue: statusRaw) ?? .pending }
    set { statusRaw = newValue.rawValue }
}
```

### Query Patterns

#### Basic Query
```swift
@Query var tasks: [TaskItem]

// With predicate
@Query(filter: #Predicate<TaskItem> { !$0.isCompleted })
var incompleteTasks: [TaskItem]

// With sort
@Query(sort: \TaskItem.createdDate, order: .reverse)
var recentTasks: [TaskItem]
```

#### Dynamic Queries
```swift
func fetchTasks(for date: Date) -> [TaskItem] {
    let start = Calendar.current.startOfDay(for: date)
    let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!

    let predicate = #Predicate<TaskItem> { task in
        task.dueDate != nil &&
        task.dueDate! >= start &&
        task.dueDate! < end
    }

    let descriptor = FetchDescriptor<TaskItem>(predicate: predicate)
    return (try? modelContext.fetch(descriptor)) ?? []
}
```

## Output

1. Model compliance summary
2. CloudKit compatibility issues (if applicable)
3. Query efficiency analysis
4. Recommended fixes with code
