# Isolated Review

Review code in isolation from its surrounding context to catch hidden assumptions.

## Technique
1. **Read the function/view alone.** Open just the function or view body without looking at the caller or parent view.
2. **Ask: what states can the inputs be in?** Consider nil, empty, negative, very large, concurrent, and error states.
3. **Verify it handles ALL states.** Not just the happy path.

## Checklist for Isolated Review
- **Optionals:** Is every optional unwrapped safely? What happens if it's nil?
- **Collections:** What if the array is empty? What if it has one item? What about thousands?
- **Strings:** What about empty strings, whitespace-only strings, or very long strings?
- **Numbers:** What about zero, negative, Int.max, NaN (for Doubles)?
- **Async:** What if the view disappears before the task completes?
- **Error paths:** Does every throwing call have meaningful error handling (not just `catch {}`)?

## View-Specific Isolation Checks
- Does this view render correctly with no data?
- Does this view handle loading states?
- Does this view show an error state?
- Is there a path where the user gets stuck (no back button, no dismiss)?
- Does the view work in both light and dark mode?
- Does the view scale with Dynamic Type?

## Why This Matters
When you read code in context, your brain fills in assumptions from surrounding code. Isolation forces you to see what the code *actually* does, not what you *think* it does.
