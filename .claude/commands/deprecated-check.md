# Deprecated API Check Command

Find deprecated APIs and suggest modern replacements.

## Target
$ARGUMENTS

## Common Deprecations

### SwiftUI Deprecations

#### Animation (iOS 15+)
```swift
// DEPRECATED
.animation(.spring())

// MODERN
.animation(.spring(), value: someValue)
```

#### NavigationView (iOS 16+)
```swift
// DEPRECATED
NavigationView {
    List { ... }
}

// MODERN
NavigationStack {
    List { ... }
}

// Or for split view
NavigationSplitView {
    // Sidebar
} detail: {
    // Detail
}
```

#### Alert (iOS 15+)
```swift
// DEPRECATED
.alert(isPresented: $showAlert) {
    Alert(title: Text("Title"))
}

// MODERN
.alert("Title", isPresented: $showAlert) {
    Button("OK") { }
}
```

#### ActionSheet (iOS 15+)
```swift
// DEPRECATED
.actionSheet(isPresented: $showSheet) { ... }

// MODERN
.confirmationDialog("Title", isPresented: $showSheet) { ... }
```

#### onChange (iOS 17+)
```swift
// DEPRECATED
.onChange(of: value) { newValue in
    // ...
}

// MODERN
.onChange(of: value) { oldValue, newValue in
    // ...
}
// Or without parameters
.onChange(of: value) {
    // ...
}
```

### UIKit Deprecations

#### UIApplication.shared.windows
```swift
// DEPRECATED
UIApplication.shared.windows.first

// MODERN
guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
      let window = scene.windows.first else { return }
```

#### Open URL
```swift
// DEPRECATED
UIApplication.shared.open(url)

// MODERN (for SwiftUI)
@Environment(\.openURL) var openURL
openURL(url)
```

### Combine Deprecations

#### Result Publisher
```swift
// DEPRECATED
Result.Publisher(result)

// MODERN
result.publisher
```

## Search Patterns

### SwiftUI
```
// Animation without value
\.animation\([^,]+\)(?!\s*,\s*value)

// NavigationView
NavigationView\s*\{

// Old alert style
\.alert\(isPresented.*Alert\(

// Old onChange
\.onChange\(of:.*\)\s*\{\s*\w+\s+in
```

### UIKit
```
// UIApplication.shared.windows
UIApplication\.shared\.windows

// keyWindow
\.keyWindow
```

## Checklist

- [ ] No deprecated SwiftUI modifiers
- [ ] No deprecated UIKit APIs
- [ ] No deprecated Foundation APIs
- [ ] Build with -Wdeprecated-declarations enabled
- [ ] Minimum deployment target APIs used appropriately

## Xcode Configuration

Enable deprecation warnings:
```
Build Settings > Swift Compiler - Warnings > Deprecations = Yes
```

## Output

1. List of deprecated APIs found
2. Modern replacement for each
3. Migration code examples
4. Deployment target considerations
