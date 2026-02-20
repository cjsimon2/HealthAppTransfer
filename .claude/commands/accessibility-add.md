# Add Accessibility Command

Add accessibility modifiers to a SwiftUI view.

## Target View
$ARGUMENTS

## Accessibility Requirements

### Core Principles

Good accessibility helps all users, not just those with disabilities:
- Clear, concise labels
- Logical focus order
- Dynamic Type support
- Sufficient color contrast

### Required Modifiers

#### 1. VoiceOver Labels
```swift
// Interactive elements MUST have labels
Button(action: startAction) {
    Image(systemName: "play.fill")
}
.accessibilityLabel("Start")
.accessibilityHint("Begins the timer")

// Custom views need labels
ProgressCircle(progress: 0.75)
    .accessibilityLabel("Progress")
    .accessibilityValue("75 percent")
```

#### 2. Grouping
```swift
// Group related elements
HStack {
    Text("Score")
    Text("100")
}
.accessibilityElement(children: .combine)
// VoiceOver reads: "Score, 100"
```

#### 3. Traits
```swift
// Buttons
.accessibilityAddTraits(.isButton)

// Headers
.accessibilityAddTraits(.isHeader)

// Decorative images
.accessibilityHidden(true)

// Live updates
.accessibilityAddTraits(.updatesFrequently)
```

#### 4. Custom Actions
```swift
.accessibilityAction(named: "Delete") {
    deleteItem()
}
```

### Common Patterns

#### Timer Display
```swift
Text(timeDisplay)
    .accessibilityLabel("Time remaining")
    .accessibilityValue(timeDisplay)
    .accessibilityAddTraits(.updatesFrequently)
```

#### Progress Indicators
```swift
ProgressView(value: progress)
    .accessibilityLabel("Download progress")
    .accessibilityValue("\(Int(progress * 100)) percent")
```

#### List Items
```swift
ItemRow(item: item)
    .accessibilityLabel(item.title)
    .accessibilityValue(item.isCompleted ? "Completed" : "Not completed")
    .accessibilityHint("Double tap to view details")
```

### Dynamic Type Support
```swift
// Use system fonts that scale
Text("Title")
    .font(.headline)  // Scales automatically

// For custom sizes
@ScaledMetric var iconSize: CGFloat = 24
Image(systemName: "star")
    .frame(width: iconSize, height: iconSize)
```

### Color Contrast
```swift
// Ensure sufficient contrast
Text("Important")
    .foregroundColor(.primary)  // Adapts to light/dark

// Don't rely on color alone
HStack {
    Circle()
        .fill(status.color)
    Text(status.label)  // Text backup for color
}
```

### Touch Targets
```swift
// Minimum 44x44 points
Button(action: action) {
    Image(systemName: "plus")
        .padding()
}
.frame(minWidth: 44, minHeight: 44)
```

## Audit Process

1. **Identify Interactive Elements**
   - Buttons, links, form inputs
   - Custom gesture handlers
   - Toggles and switches

2. **Check Information Elements**
   - Progress indicators
   - Status displays
   - Dynamic content

3. **Review Decorative Elements**
   - Hide purely decorative images
   - Don't label decorative dividers

4. **Test Focus Order**
   - Tab through elements logically
   - Important actions accessible first

## Output Format

For the target view, provide:
1. Current accessibility status
2. Missing accessibility features
3. Code additions with exact placement
4. Testing instructions for VoiceOver
