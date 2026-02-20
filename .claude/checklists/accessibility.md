# Accessibility Checklist

## VoiceOver Support

### Labels & Hints
- [ ] All interactive elements have accessibility labels
- [ ] Labels are concise but descriptive
- [ ] Hints explain non-obvious actions
- [ ] Labels don't include element type (VoiceOver adds this)
- [ ] Button labels describe action, not appearance ("Add item" not "Plus button")

### Element Grouping
- [ ] Related elements grouped with `.accessibilityElement(children: .combine)`
- [ ] Decorative elements hidden with `.accessibilityHidden(true)`
- [ ] Complex views have custom accessibility representations
- [ ] Reading order makes logical sense

### Actions
- [ ] Custom actions provided for complex interactions
- [ ] Swipe actions have accessibility alternatives
- [ ] Drag-and-drop has accessibility alternative
- [ ] Magic tap performs primary action where appropriate

### Focus Management
- [ ] Focus moves logically through interface
- [ ] Focus announcements made for important changes
- [ ] Modal views trap focus appropriately
- [ ] Custom focus behavior uses `@AccessibilityFocusState`

## Dynamic Type

### Text Scaling
- [ ] All text uses system fonts or `@ScaledMetric`
- [ ] Text scales smoothly from xSmall to AX5
- [ ] No text truncation at larger sizes (or graceful handling)
- [ ] Line limits adjusted for accessibility sizes
- [ ] Minimum readable at smallest size

### Layout Adaptation
- [ ] Horizontal layouts stack vertically at large sizes
- [ ] Icons scale with text using `@ScaledMetric`
- [ ] Touch targets remain adequate at all sizes
- [ ] Scrolling enabled for content that doesn't fit

### Testing
- [ ] Tested at accessibility1 size
- [ ] Tested at accessibility5 size
- [ ] No layout breaking at any size
- [ ] Content remains usable at all sizes

## Color & Contrast

### Contrast Requirements
- [ ] Text meets 4.5:1 contrast ratio (body text)
- [ ] Large text meets 3:1 contrast ratio
- [ ] Interactive elements meet 3:1 contrast
- [ ] Focus indicators clearly visible

### Color Independence
- [ ] Information not conveyed by color alone
- [ ] Charts/graphs have patterns or labels
- [ ] Error states have icons, not just red color
- [ ] Success/warning states have additional indicators

### Color Scheme Support
- [ ] Light mode fully functional
- [ ] Dark mode fully functional
- [ ] High contrast mode supported
- [ ] Increased contrast mode works correctly

## Motion & Animation

### Reduce Motion
- [ ] `@Environment(\.accessibilityReduceMotion)` checked
- [ ] Alternative transitions for animations
- [ ] Auto-playing animations can be paused
- [ ] Parallax effects disabled when reduced motion on

### Vestibular Safety
- [ ] No rapidly flashing content (< 3 flashes/second)
- [ ] Large-scale motion can be disabled
- [ ] Sliding/zooming effects respect reduce motion
- [ ] Background animations can be stopped

## Touch & Interaction

### Touch Targets
- [ ] Minimum 44x44 pt touch targets
- [ ] Adequate spacing between targets (8pt minimum)
- [ ] Touch targets work in both orientations
- [ ] No precision-demanding gestures as only option

### Gestures
- [ ] Standard gestures used where possible
- [ ] Complex gestures have simple alternatives
- [ ] Gesture timing is adjustable or generous
- [ ] No time-limited interactions (or can be extended)

### Input Methods
- [ ] Full keyboard navigation (iPad)
- [ ] External keyboard shortcuts documented
- [ ] Switch Control compatible
- [ ] Voice Control compatible

## Cognitive Accessibility

### Clarity
- [ ] Clear, simple language used
- [ ] Consistent terminology throughout
- [ ] Icons have labels or are self-explanatory
- [ ] Error messages are clear and actionable

### Memory & Attention
- [ ] Important information persists on screen
- [ ] No auto-advancing content
- [ ] Form data preserved during navigation
- [ ] Clear visual hierarchy

### Navigation
- [ ] Consistent navigation structure
- [ ] Current location always clear
- [ ] Easy to return to home/start
- [ ] No deep navigation without breadcrumbs

## Testing Checklist

### Tools
- [ ] Accessibility Inspector audit run
- [ ] VoiceOver testing on device
- [ ] Switch Control testing
- [ ] Voice Control testing
- [ ] Large text testing

### Scenarios
- [ ] Complete core user journey with VoiceOver
- [ ] Complete core user journey with keyboard only
- [ ] Complete core user journey at AX5 text size
- [ ] Complete core user journey with reduced motion
- [ ] Complete core user journey with increased contrast

### Documentation
- [ ] Accessibility statement written
- [ ] Known limitations documented
- [ ] Accessibility contact provided
- [ ] Conformance level claimed (WCAG)
