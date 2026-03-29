# Pattern Matching

When implementing new features, first find 2-3 existing similar implementations in the codebase and follow their patterns exactly.

## Process
1. **Identify the pattern type.** Is this a new View, ViewModel, Model, Service, or Test?
2. **Search the codebase for similar implementations.** Use grep/find to locate 2-3 examples.
3. **Study their structure.** Note file organization, naming conventions, property ordering, method signatures.
4. **Follow the pattern exactly.** Do not innovate on structure unless the existing pattern has a clear deficiency.

## What to Match
- **File naming:** If existing ViewModels are `ExportViewModel.swift`, name yours `ImportViewModel.swift` — not `VMImport.swift`.
- **Property ordering:** If existing Views put `@Environment` first, then `@State`, then computed properties — follow that order.
- **Method signatures:** If existing services use `async throws -> Result`, use the same.
- **Error handling:** If the project uses typed errors, use typed errors. If it uses `Error`, use `Error`.
- **Access control:** If existing ViewModels are `@MainActor class MyViewModel: ObservableObject`, match that exactly.
- **Test structure:** If tests use Arrange/Act/Assert with specific helper methods, follow suit.

## When to Deviate
- Only deviate when the existing pattern has a documented or obvious deficiency.
- Document the deviation and rationale in a code comment.
- Update LEARNINGS.md if this establishes a new preferred pattern.

## Benefits
- Consistency reduces cognitive load for all contributors.
- Pattern deviations are immediately visible in code review.
- New developers can learn the codebase by studying one example of each pattern type.
