# iPad Compatibility Check Command

Review iPad-specific layout and navigation issues.

## Target
$ARGUMENTS

## iPad Considerations

### Navigation Patterns

#### iPhone vs iPad
```swift
struct ContentView: View {
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        if sizeClass == .compact {
            // iPhone: Tab-based navigation
            TabView {
                // ...
            }
        } else {
            // iPad: Split view navigation
            NavigationSplitView {
                Sidebar()
            } detail: {
                DetailView()
            }
        }
    }
}
```

### Size Classes

| Device | Orientation | Horizontal | Vertical |
|--------|-------------|------------|----------|
| iPhone | Portrait | Compact | Regular |
| iPhone | Landscape | Compact* | Compact |
| iPad | Portrait | Regular | Regular |
| iPad | Landscape | Regular | Regular |
| iPad Split | 1/3 | Compact | Regular |

*iPhone Plus/Max in landscape can be Regular

## Review Checklist

### Layout
- [ ] Views adapt to size class changes
- [ ] No hardcoded widths that break on iPad
- [ ] Proper use of GeometryReader (if needed)
- [ ] Content readable at iPad size
- [ ] Split view behavior correct

### Navigation
- [ ] NavigationSplitView for iPad
- [ ] Sidebar content appropriate
- [ ] Detail view selection works
- [ ] Back button behavior correct
- [ ] Keyboard shortcuts defined

### Keyboard Shortcuts
```swift
.keyboardShortcut("n", modifiers: .command)  // Cmd+N
```

### Pointer Support (iPadOS)
```swift
Button("Action") { }
    .hoverEffect(.lift)  // Pointer hover effect
```

### Multitasking
- [ ] Works in Split View
- [ ] Works in Slide Over
- [ ] State preserved during resize
- [ ] Minimum width constraints reasonable

## Common Issues

### 1. Hardcoded Dimensions
```swift
// WRONG - Doesn't adapt
.frame(width: 375)

// RIGHT - Flexible layout
.frame(maxWidth: .infinity)
// Or use percentages
.frame(width: geometry.size.width * 0.8)
```

### 2. Missing Size Class Adaptation
```swift
// WRONG - Same layout everywhere
NavigationView {
    List { ... }
}

// RIGHT - Adapts to device
@Environment(\.horizontalSizeClass) var sizeClass

var body: some View {
    if sizeClass == .regular {
        NavigationSplitView { ... }
    } else {
        NavigationStack { ... }
    }
}
```

### 3. Touch Targets Too Small
```swift
// iPad users may use fingers or Apple Pencil
// Ensure touch targets are at least 44x44
Button(action: action) {
    Image(systemName: "plus")
}
.frame(minWidth: 44, minHeight: 44)
```

### 4. Text Too Small
```swift
// Consider larger text on iPad
.font(sizeClass == .regular ? .title2 : .body)
```

### 5. Missing Keyboard Support
```swift
// Add keyboard shortcuts for common actions
.keyboardShortcut("s", modifiers: .command)  // Save
.keyboardShortcut(.delete, modifiers: .command)  // Delete
.keyboardShortcut("n", modifiers: .command)  // New
```

## Testing Checklist

- [ ] Test on iPad simulator
- [ ] Test in Split View (1/3, 1/2, 2/3)
- [ ] Test in Slide Over
- [ ] Test rotation
- [ ] Test with keyboard connected
- [ ] Test with trackpad/mouse

## Output

1. Size class handling review
2. Navigation structure analysis
3. Layout issues found
4. Keyboard shortcut suggestions
5. Recommended fixes
