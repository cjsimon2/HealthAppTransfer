# SwiftUI View Checklist

## View Structure

### Organization
- [ ] MARK comments used to organize sections
- [ ] Properties ordered: Environment, State, Bindings, Constants
- [ ] Body is concise (under 50 lines)
- [ ] Subviews extracted as computed properties or separate structs
- [ ] Preview provider included

### Naming
- [ ] View name describes purpose
- [ ] View suffix used (e.g., `TaskListView`)
- [ ] Private subviews prefixed with purpose
- [ ] Boolean properties prefixed with `is`, `has`, `should`

## State Management

### Property Wrappers
- [ ] `@State` used for view-local value types only
- [ ] `@StateObject` used when view creates the ObservableObject
- [ ] `@ObservedObject` used for passed-in or singleton objects
- [ ] `@Binding` used for two-way parent connection
- [ ] `@Environment` used for system values

### State Design
- [ ] Minimum necessary state stored
- [ ] Derived values use computed properties
- [ ] State initialized with sensible defaults
- [ ] No force unwrapping of state
- [ ] State changes happen on main thread

## Layout

### Spacing & Padding
- [ ] Consistent spacing scale used (8, 16, 24, 32)
- [ ] Standard horizontal padding (16-20pt)
- [ ] Bottom padding for tab bar clearance (if applicable)
- [ ] Safe area handling correct

### Sizing
- [ ] No hardcoded widths that break on different devices
- [ ] Flexible layouts with `.frame(maxWidth: .infinity)`
- [ ] Minimum touch targets (44x44pt)
- [ ] `GeometryReader` used sparingly

### Scrolling
- [ ] `ScrollView` used for content that may exceed screen
- [ ] `LazyVStack`/`LazyHStack` for long lists
- [ ] Keyboard avoidance handled
- [ ] Pull-to-refresh (if applicable)

## Navigation

### Navigation Patterns
- [ ] `NavigationStack` used (iOS 16+)
- [ ] `navigationDestination` for type-safe navigation
- [ ] Navigation titles set appropriately
- [ ] Back button behavior correct

### Presentation
- [ ] Sheets use `presentationDetents`
- [ ] Alerts and confirmations use system dialogs
- [ ] Dismiss actions provided for modal views
- [ ] Deep links handled

## Performance

### Rendering
- [ ] Expensive computations moved to ViewModel
- [ ] `LazyVStack`/`LazyHStack` for lists over 20 items
- [ ] Images loaded asynchronously
- [ ] `drawingGroup()` for complex graphics

### Updates
- [ ] View only redraws when necessary
- [ ] Equatable views use `.equatable()` where beneficial
- [ ] Animation values specified (`.animation(_, value:)`)
- [ ] No side effects in body

## Accessibility

### VoiceOver
- [ ] All interactive elements have labels
- [ ] Decorative elements hidden
- [ ] Custom actions for complex interactions
- [ ] Logical reading order

### Dynamic Type
- [ ] System fonts used (or `@ScaledMetric`)
- [ ] Layout adapts to large text
- [ ] Text not truncated inappropriately

### Other
- [ ] Reduce motion respected
- [ ] High contrast supported
- [ ] Minimum contrast ratios met

## Error Handling

### Loading States
- [ ] Loading indicator shown during async operations
- [ ] Skeleton/placeholder UI (if appropriate)
- [ ] Cancel capability for long operations

### Error States
- [ ] User-friendly error messages
- [ ] Retry option provided
- [ ] Error details accessible (for debugging)
- [ ] Empty state design included

## Previews

### Preview Coverage
- [ ] Default preview
- [ ] Different data states (empty, loading, error, populated)
- [ ] Dark mode preview
- [ ] Different device sizes
- [ ] Accessibility sizes

### Preview Configuration
```swift
#Preview {
    ContentView()
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}

#Preview("Large Text") {
    ContentView()
        .dynamicTypeSize(.accessibility3)
}
```

## Code Quality

### Style
- [ ] 4-space indentation
- [ ] No trailing whitespace
- [ ] Single blank line between sections
- [ ] Consistent brace style

### Best Practices
- [ ] No force unwrapping in view body
- [ ] No side effects in body
- [ ] Colors from asset catalog or semantic colors
- [ ] Strings localized (or marked for localization)
- [ ] SF Symbols used where appropriate

### Documentation
- [ ] Complex logic explained in comments
- [ ] Public APIs documented
- [ ] Non-obvious behavior explained

## Testing

### Unit Tests
- [ ] ViewModel logic tested
- [ ] Data transformations tested
- [ ] Edge cases covered

### UI Tests
- [ ] Main user flows covered
- [ ] Accessibility identifiers added for test targets
- [ ] Tests don't depend on timing

### Manual Testing
- [ ] Works on minimum supported device
- [ ] Works on latest device
- [ ] Rotation handling correct
- [ ] Keyboard handling correct
