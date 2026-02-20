# SwiftUI View Audit Command

Audit a SwiftUI view for best practices and common issues.

## Target View
$ARGUMENTS

## Audit Checklist

### Structure & Organization

- [ ] File header comment present
- [ ] MARK sections organize code logically
- [ ] View body is under 50 lines (extract subviews if needed)
- [ ] Preview provider included and functional
- [ ] Subviews extracted as computed properties or separate structs

### State Management

- [ ] `@State` used only for view-local state
- [ ] `@StateObject` used for owned ObservableObjects
- [ ] `@ObservedObject` used for passed-in/shared objects
- [ ] `@EnvironmentObject` used appropriately
- [ ] State initialized properly (not recreated on re-render)

### Property Wrapper Guidelines
```swift
// @State - View-local value types
@State private var isExpanded = false

// @StateObject - View owns the object
@StateObject private var viewModel = MyViewModel()

// @ObservedObject - Object passed in or shared singleton
@ObservedObject var settings = AppSettings.shared

// @Binding - Two-way connection to parent
@Binding var selectedItem: Item?
```

### Layout & Spacing

- [ ] 8pt spacing scale followed (8, 16, 24, 32)
- [ ] Consistent horizontal padding (typically 16-20)
- [ ] ScrollView content has bottom padding for tab bar clearance
- [ ] Safe areas handled correctly

### Navigation

- [ ] Uses `.sheet()` for modal presentation
- [ ] Navigation title set appropriately
- [ ] Back button behavior correct
- [ ] iPad compatibility considered

### Accessibility

- [ ] VoiceOver labels on interactive elements
- [ ] Dynamic Type supported
- [ ] Minimum 44x44 touch targets
- [ ] Color not sole indicator of state

### Performance

- [ ] No expensive operations in view body
- [ ] Lists use `LazyVStack` when appropriate
- [ ] Animations use `.animation(_:value:)` (not deprecated form)
- [ ] Complex graphics use `.drawingGroup()`

### Common Issues

**Tab Bar Overlap:**
```swift
ScrollView {
    VStack {
        // content
    }
    .padding(.bottom, 100)  // Tab bar clearance
}
```

**Deprecated Animation:**
```swift
// WRONG
.animation(.spring())

// RIGHT
.animation(.spring(), value: someValue)
```

## Output Format

### Score Card
- Structure: X/10
- State Management: X/10
- Layout: X/10
- Accessibility: X/10
- Performance: X/10

### Issues Found
List each issue with:
1. Severity (Critical/Warning/Info)
2. Location (line number)
3. Problem description
4. Suggested fix with code
