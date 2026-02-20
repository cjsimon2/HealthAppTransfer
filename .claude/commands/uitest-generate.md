# UI Test Generation Command

Generate XCUITest tests for a view or feature.

## Target
$ARGUMENTS

## UI Test Structure

### Basic Test Class
```swift
import XCTest

final class MyFeatureUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testFeatureFlow() throws {
        // Test implementation
    }
}
```

### App Launch Arguments
```swift
// In app's @main
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if CommandLine.arguments.contains("--uitesting") {
                        // Reset state for testing
                    }
                }
        }
    }
}
```

## Common Test Patterns

### Finding Elements
```swift
// By accessibility identifier
let button = app.buttons["addButton"]

// By label text
let button = app.buttons["Add Item"]

// By predicate
let button = app.buttons.matching(
    NSPredicate(format: "label CONTAINS 'Add'")
).firstMatch
```

### Accessibility Identifiers
```swift
// In SwiftUI view
Button("Add") { }
    .accessibilityIdentifier("addButton")

// In test
app.buttons["addButton"].tap()
```

### Interactions
```swift
// Tap
app.buttons["submit"].tap()

// Type text
app.textFields["emailField"].tap()
app.textFields["emailField"].typeText("test@example.com")

// Swipe
app.tables.cells.firstMatch.swipeLeft()

// Long press
app.buttons["item"].press(forDuration: 1.0)
```

### Assertions
```swift
// Existence
XCTAssertTrue(app.buttons["submit"].exists)

// Wait for element
let button = app.buttons["submit"]
XCTAssertTrue(button.waitForExistence(timeout: 5))

// Label/value
XCTAssertEqual(app.staticTexts["count"].label, "5")

// Enabled state
XCTAssertTrue(app.buttons["submit"].isEnabled)
```

### Navigation
```swift
// Navigate to tab
app.tabBars.buttons["Settings"].tap()

// Navigate back
app.navigationBars.buttons.element(boundBy: 0).tap()

// Dismiss sheet
app.buttons["Done"].tap()
// Or swipe down
app.swipeDown()
```

## Test Templates

### List CRUD Operations
```swift
func testAddItem() throws {
    // Tap add button
    app.buttons["addButton"].tap()

    // Fill form
    app.textFields["titleField"].tap()
    app.textFields["titleField"].typeText("New Item")

    // Save
    app.buttons["saveButton"].tap()

    // Verify item appears
    XCTAssertTrue(app.staticTexts["New Item"].waitForExistence(timeout: 2))
}

func testDeleteItem() throws {
    // Find item cell
    let cell = app.cells["itemCell_0"]
    XCTAssertTrue(cell.exists)

    // Swipe to delete
    cell.swipeLeft()
    app.buttons["Delete"].tap()

    // Verify deleted
    XCTAssertFalse(cell.exists)
}
```

### Form Validation
```swift
func testFormValidation() throws {
    // Try submit without required fields
    app.buttons["submit"].tap()

    // Verify error shown
    XCTAssertTrue(app.staticTexts["titleRequired"].exists)

    // Fill required field
    app.textFields["titleField"].typeText("Valid Title")
    app.buttons["submit"].tap()

    // Verify success
    XCTAssertTrue(app.staticTexts["Success"].waitForExistence(timeout: 2))
}
```

### Navigation Flow
```swift
func testNavigationFlow() throws {
    // Start at home
    XCTAssertTrue(app.navigationBars["Home"].exists)

    // Navigate to detail
    app.cells.firstMatch.tap()
    XCTAssertTrue(app.navigationBars["Detail"].waitForExistence(timeout: 2))

    // Navigate back
    app.navigationBars.buttons.firstMatch.tap()
    XCTAssertTrue(app.navigationBars["Home"].exists)
}
```

## Accessibility Identifiers File

Create centralized identifiers:
```swift
// AccessibilityIdentifiers.swift
enum AccessibilityIdentifiers {
    enum Home {
        static let addButton = "home_addButton"
        static let itemList = "home_itemList"
    }

    enum Detail {
        static let titleField = "detail_titleField"
        static let saveButton = "detail_saveButton"
    }
}
```

## Output

Generate:
1. Test class with setup/teardown
2. Tests for main user flows
3. Required accessibility identifiers
4. Mock/test data setup code
