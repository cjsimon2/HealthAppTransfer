# SwiftUI Accessibility

## Core Accessibility Modifiers

### Labels and Hints
```swift
Button(action: addItem) {
    Image(systemName: "plus")
}
.accessibilityLabel("Add item")
.accessibilityHint("Double tap to add a new item to your list")
```

### Values and Traits
```swift
Slider(value: $volume, in: 0...100)
    .accessibilityValue("\(Int(volume)) percent")
    .accessibilityAddTraits(.allowsDirectInteraction)
```

### Hiding Decorative Elements
```swift
// Hide decorative images from VoiceOver
Image("decorative-divider")
    .accessibilityHidden(true)

// Or combine elements
HStack {
    Image(systemName: "star.fill")
    Text("Favorite")
}
.accessibilityElement(children: .combine)
```

## VoiceOver Support

### Custom Actions
```swift
struct TaskRow: View {
    let task: Task
    let onComplete: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Text(task.title)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(task.title)
        .accessibilityAddTraits(task.isCompleted ? .isSelected : [])
        .accessibilityAction(named: "Complete") {
            onComplete()
        }
        .accessibilityAction(named: "Delete") {
            onDelete()
        }
    }
}
```

### Rotor Actions
```swift
List(items) { item in
    ItemRow(item: item)
}
.accessibilityRotorEntry(id: item.id, in: .headings)
```

### Focus Management
```swift
struct FormView: View {
    @AccessibilityFocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .accessibilityFocused($focusedField, equals: .email)

            SecureField("Password", text: $password)
                .accessibilityFocused($focusedField, equals: .password)

            Button("Login") {
                if email.isEmpty {
                    focusedField = .email
                }
            }
        }
    }
}
```

## Dynamic Type Support

### Using System Fonts
```swift
// Always use system fonts for automatic scaling
Text("Title")
    .font(.headline)

Text("Body text")
    .font(.body)

// Custom sizes that scale
Text("Custom")
    .font(.system(size: 17, weight: .medium, design: .rounded))
```

### Scaled Metrics
```swift
struct ScaledView: View {
    @ScaledMetric(relativeTo: .body) var iconSize = 24
    @ScaledMetric(relativeTo: .body) var spacing = 16

    var body: some View {
        HStack(spacing: spacing) {
            Image(systemName: "star")
                .frame(width: iconSize, height: iconSize)
            Text("Favorite")
        }
    }
}
```

### Layout Adaptation
```swift
struct AdaptiveStack: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize >= .accessibility1 {
            // Stack vertically for large text
            VStack(alignment: .leading) {
                content
            }
        } else {
            // Horizontal for normal text
            HStack {
                content
            }
        }
    }
}
```

## Color and Contrast

### High Contrast Support
```swift
struct ContrastAwareView: View {
    @Environment(\.colorSchemeContrast) var contrast

    var body: some View {
        Text("Important")
            .foregroundColor(contrast == .increased ? .primary : .secondary)
    }
}
```

### Semantic Colors
```swift
// Use semantic colors that adapt
Text("Error")
    .foregroundColor(.red)  // Adapts to accessibility settings

// Custom colors with accessibility variants
extension Color {
    static let customBackground = Color("CustomBackground")  // Define in Assets
}
```

### Reduce Transparency
```swift
struct BlurredBackground: View {
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency

    var body: some View {
        if reduceTransparency {
            Color.systemBackground
        } else {
            Color.systemBackground.opacity(0.8)
                .background(.ultraThinMaterial)
        }
    }
}
```

## Motion and Animation

### Reduce Motion
```swift
struct AnimatedView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isExpanded = false

    var body: some View {
        VStack {
            content
        }
        .animation(reduceMotion ? .none : .spring(), value: isExpanded)
    }
}
```

### Alternative Transitions
```swift
extension AnyTransition {
    static var accessibleSlide: AnyTransition {
        @Environment(\.accessibilityReduceMotion) var reduceMotion
        return reduceMotion ? .opacity : .slide
    }
}
```

## Touch Targets

### Minimum Size Requirements
```swift
// Ensure 44x44pt minimum
Button(action: action) {
    Image(systemName: "gear")
        .frame(minWidth: 44, minHeight: 44)
}

// Or use contentShape
Button(action: action) {
    Image(systemName: "gear")
}
.frame(width: 44, height: 44)
.contentShape(Rectangle())
```

### Spacing for Touch
```swift
HStack(spacing: 16) {  // Adequate spacing between targets
    Button("Edit") { }
        .frame(minWidth: 44, minHeight: 44)

    Button("Delete") { }
        .frame(minWidth: 44, minHeight: 44)
}
```

## Testing Accessibility

### Accessibility Inspector
1. Open Accessibility Inspector in Xcode
2. Target the simulator or device
3. Hover over elements to inspect labels, hints, traits

### VoiceOver Testing
```swift
// Enable VoiceOver in Settings > Accessibility > VoiceOver
// Or use Control Center shortcut

// Test navigation:
// - Swipe left/right to move between elements
// - Double-tap to activate
// - Three-finger swipe to scroll
```

### Audit Checklist
- [ ] All interactive elements have labels
- [ ] Images have descriptions or are hidden
- [ ] Forms announce errors accessibly
- [ ] Custom controls have proper traits
- [ ] Text scales with Dynamic Type
- [ ] Touch targets are at least 44x44pt
- [ ] Color is not the only indicator
- [ ] Animations respect Reduce Motion
- [ ] Content works in portrait and landscape
