# HealthAppTransfer

An iOS application built with SwiftUI.

## Project Structure

```
HealthAppTransfer/
├── HealthAppTransfer/
│   ├── App/                   # App entry point
│   ├── Views/                 # SwiftUI views
│   ├── ViewModels/            # MVVM view models
│   ├── Models/                # Data models
│   ├── Services/              # Business logic, singletons
│   ├── Extensions/            # Swift extensions
│   └── Resources/             # Assets, strings
├── HealthAppTransferTests/     # Unit tests
└── HealthAppTransferUITests/   # UI tests
```

## Tech Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Architecture:** MVVM with Combine
- **Minimum iOS:** 17.0
- **IDE:** Xcode 15+

## Extended Thinking Triggers

Use these phrases to activate extended thinking for complex tasks:

| Trigger | Token Budget | Use For |
|---------|--------------|---------|
| "think" | ~2K tokens | Quick analysis, simple debugging |
| "think hard" | ~10K tokens | Complex debugging, multi-file changes |
| "ultrathink" | ~32K tokens | Architecture decisions, major refactors |

## Anti-Overengineering Framework

Before adding any abstraction, helper, or "improvement", ask:

```
Will this code need this feature in the next 2 weeks?
├── YES → Implement it
└── NO → Don't implement it
```

### Pattern Analysis Checklist
- [ ] Is there existing code doing something similar? → Copy its pattern
- [ ] Am I adding a helper for a one-time use? → Don't
- [ ] Am I making this "configurable" for no current need? → Don't
- [ ] Am I adding error handling for impossible scenarios? → Don't
- [ ] Would a junior developer understand this in 5 minutes? → If no, simplify

### NEVER Do These
- Create abstractions for single-use code
- Add "just in case" parameters or configurations
- Build factory patterns without multiple concrete implementations
- Over-engineer ViewModels for simple views

### ALWAYS Do These
- Copy existing patterns before inventing new ones
- Write the simplest code that works
- Delete code instead of commenting it out
- Use concrete types unless polymorphism is actually needed

## Verification Patterns

### 5-Step Verification Sequence
1. **Build**: Cmd+B in Xcode (no errors)
2. **Tests Pass**: Cmd+U to run tests
3. **Feature Works**: Run in Simulator
4. **No Regressions**: Test existing flows
5. **Acceptance Met**: Check each criterion

### 3-Attempt Verification Loop
When a build or test fails:

```
Attempt 1: Fix the specific error reported
           ↓ Still failing?
Attempt 2: Re-read context, try a different approach
           ↓ Still failing?
Attempt 3: STOP. Document the blocker. Escalate.
```

## Session Management

### Context Checkpoints
At natural break points, update STATE.md (if it exists) with:
- Current subtask progress
- Key decisions made
- Blockers encountered
- Next steps

### Handoff Protocol
When ending a session or hitting context limits:
1. Create/update `handoff.md` with session summary
2. List all changes with file paths
3. Document incomplete work
4. Note decisions and rationale
5. Provide clear next steps

### Context Recovery Priority
1. `handoff.md` - Most recent session state
2. `STATE.md` - Ongoing project state
3. `git log --oneline -10` - Recent changes
4. This CLAUDE.md file - Project conventions

## Persistent Learning System

This project uses an automatic learning system:

- **STATE.md** - Auto-updated project state, tasks, and metrics
- **LEARNINGS.md** - Accumulated patterns, mistakes, and insights
- **handoff.md** - Session continuity (created by /session-summary)

### Key Commands
| Command | Purpose |
|---------|---------|
| `/learn` | Record patterns, mistakes, or insights |
| `/session-summary` | Create handoff for next session |
| `/checkyourwork` | Self-review with learning integration |

Use `/learn pattern: [description]` to record what works, or `/learn mistake: [description]` to record what to avoid.

## Development Guidelines

### SwiftUI Patterns

- Use MVVM architecture with `@MainActor` ViewModels
- Keep views small and focused (body under 50 lines)
- Extract subviews as computed properties or separate structs
- Use `@StateObject` for view-owned objects
- Use `@ObservedObject` for passed-in or singleton objects
- Follow 8pt spacing scale (8, 16, 24, 32)

### State Management

| Wrapper | Use Case |
|---------|----------|
| `@State` | View-local value types |
| `@StateObject` | View creates ObservableObject |
| `@ObservedObject` | Passed-in or singleton ObservableObject |
| `@Binding` | Two-way parent connection |

### Code Style

- 4-space indentation
- `UpperCamelCase` for types
- `lowerCamelCase` for properties/methods
- Use `// MARK: -` to organize files
- Prefer `guard` for early returns
- Always use `[weak self]` in closures

### Accessibility

- Add accessibility labels to all interactive elements
- Support Dynamic Type with system fonts
- Minimum 44x44 touch targets
- Test with VoiceOver

### App Store Compliance

- No private API usage
- Proper data privacy handling
- Required device capabilities declared
- App Transport Security compliance

## Quick Reference

### Common Commands
| Command | Purpose |
|---------|---------|
| Cmd+B | Build |
| Cmd+U | Run tests |
| Cmd+R | Run app |
| `/checkyourwork` | Self-review checklist |
| `/session-summary` | Create handoff summary |

### View & Layout Commands
- `/view-audit` - Audit SwiftUI views for best practices
- `/state-review` - Review state management patterns
- `/preview-fix` - Fix SwiftUI preview issues
- `/ipad-check` - Check iPad compatibility

### Data & Persistence Commands
- `/swiftdata-review` - Review SwiftData models and queries
- `/cloudkit-check` - Check CloudKit sync implementation

### Code Quality Commands
- `/accessibility-add` - Add accessibility features to views
- `/memory-audit` - Find memory leaks and retain cycles
- `/deprecated-check` - Find deprecated APIs
- `/combine-check` - Review Combine usage

### Testing & Release Commands
- `/uitest-generate` - Generate UI tests
- `/appstore-audit` - App Store compliance check
- `/widget-review` - Review WidgetKit implementation

## Skills

- `swiftui-patterns` - SwiftUI best practices and view structure
- `swift-safety` - Safe Swift patterns (optionals, errors, memory)
- `swiftui-performance` - Performance optimization for SwiftUI
- `swiftui-accessibility` - Accessibility implementation guide
- `mvvm-patterns` - MVVM architecture patterns
- `combine-patterns` - Reactive programming with Combine
- `swiftdata-patterns` - SwiftData persistence patterns
- `watchos-patterns` - watchOS development guide
- `widget-patterns` - WidgetKit implementation guide

## Checklists

- `appstore` - App Store submission checklist
- `accessibility` - Accessibility compliance checklist
- `release` - Release preparation checklist
- `swiftui-view` - SwiftUI view quality checklist

## Review Roles

The `.claude/reviews/roles/` directory contains 14 specialist review roles:

1. **Swift Reviewer** - Code quality, safety, modern Swift
2. **SwiftUI Specialist** - View patterns, state management, performance
3. **Architect** - MVVM compliance, data layer, scalability
4. **QA Engineer** - Bug hunting, edge cases, error handling
5. **Security Engineer** - Data protection, secure coding
6. **Performance Engineer** - Optimization, profiling
7. **Accessibility Specialist** - VoiceOver, Dynamic Type, WCAG
8. **App Store Reviewer** - Guidelines compliance, rejection risks
9. **Data Engineer** - SwiftData, relationships, sync
10. **UX Designer** - Usability, HIG compliance
11. **Technical Writer** - Documentation, user-facing copy
12. **Release Manager** - Versioning, CI/CD, deployment
13. **Watch Specialist** - watchOS, complications, connectivity
14. **Widget Specialist** - WidgetKit, timelines, interactivity

## Example View Structure

```swift
struct MyView: View {
    // MARK: - Environment
    @Environment(\.horizontalSizeClass) var sizeClass

    // MARK: - Observed Objects
    @StateObject private var viewModel = MyViewModel()

    // MARK: - State
    @State private var isLoading = false

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Content
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)  // Tab bar clearance
        }
        .task { await viewModel.loadData() }
    }
}
```

## Example ViewModel

```swift
@MainActor
class MyViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var error: Error?

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await fetchItems()
        } catch {
            self.error = error
        }
    }
}
```
