# CloudKit Sync Check Command

Check CloudKit sync implementation.

## Target
$ARGUMENTS

## CloudKit Sync Options

### 1. SwiftData + CloudKit (Automatic)
```swift
let schema = Schema([TaskItem.self])
let cloudConfig = ModelConfiguration(
    schema: schema,
    cloudKitDatabase: .automatic
)
```

### 2. iCloud Key-Value Store (Manual)
```swift
let kvStore = NSUbiquitousKeyValueStore.default
kvStore.set(value, forKey: "myKey")
kvStore.synchronize()
```

### 3. CloudKit Database (Direct)
```swift
let container = CKContainer.default()
let database = container.privateCloudDatabase
```

## Review Checklist

### SwiftData CloudKit
- [ ] All `@Model` properties have default values
- [ ] No unsupported types
- [ ] Arrays stored as JSON Data
- [ ] Relationships are simple (prefer ID references)
- [ ] Model changes are backward compatible

### iCloud KVS
- [ ] Not exceeding 1MB total limit
- [ ] Not exceeding 64KB per key
- [ ] Listening for external changes
- [ ] Handling sync conflicts gracefully

### Error Handling
- [ ] Network unavailable handled
- [ ] iCloud not signed in handled
- [ ] Quota exceeded handled
- [ ] Sync conflicts resolved

## Common Issues

### 1. Not Handling External Changes
```swift
// WRONG - Data stale after sync from other device
class MyManager {
    var data: Data?

    init() {
        data = kvStore.data(forKey: "myKey")
        // Never updates when synced!
    }
}

// RIGHT - Listen for changes
class MyManager {
    @Published var data: Data?

    init() {
        loadData()

        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvStore,
            queue: .main
        ) { [weak self] notification in
            guard let changedKeys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String],
                  changedKeys.contains("myKey") else { return }
            self?.loadData()
        }
    }
}
```

### 2. Large Data in KVS
```swift
// WRONG - May exceed limits
kvStore.set(hugeData, forKey: "data")

// RIGHT - Use CloudKit or SwiftData for large data
```

### 3. Missing Migration
```swift
// When changing encoded types, handle old format
if let data = kvStore.data(forKey: "items") {
    // Try new format first
    if let items = try? JSONDecoder().decode([NewItem].self, from: data) {
        self.items = items
    }
    // Fall back to old format
    else if let old = try? JSONDecoder().decode([OldItem].self, from: data) {
        self.items = old.map { NewItem(from: $0) }
    }
}
```

## Testing CloudKit

1. **Setup:** Sign into same iCloud on two devices/simulators
2. **Test Create:** Create on device A, verify on B
3. **Test Update:** Modify on A, verify on B
4. **Test Delete:** Delete on A, verify removed on B
5. **Test Conflict:** Modify same item on both
6. **Test Offline:** Make changes offline, verify sync when online

## Output

1. Sync mechanism analysis
2. Compatibility issues found
3. Missing sync handlers
4. Recommended fixes
