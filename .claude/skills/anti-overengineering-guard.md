# Anti-Overengineering Guard

Before adding any abstraction, protocol, generic, or architectural layer, answer these three questions:

## 1. Does This Solve a Current Problem?
- Is there a concrete, present-day issue this abstraction addresses?
- "We might need this later" is NOT a valid reason.
- If the problem is hypothetical, stop. Solve it when it actually exists.

## 2. Will It Be Used More Than Once?
- Is there a second call site today (not "someday")?
- One usage does not justify a protocol, generic wrapper, or factory.
- Wait for the duplication to appear, then extract.

## 3. Is the Simpler Approach Truly Inadequate?
- Write the straightforward version first.
- Measure or observe the actual pain point before refactoring.
- A 10-line function is almost always better than a 3-file abstraction.

## If Any Answer Is No — Keep It Simple
- Inline the logic.
- Use concrete types instead of protocols (until you need a second conformance).
- Prefer direct function calls over dependency injection (until you need testability).
- Remember: code is read far more than written. Simplicity is a feature.

## Red Flags of Overengineering
- Creating a protocol with only one conforming type.
- Adding a "Manager" or "Coordinator" class with one method.
- Generic parameters that are only ever one type.
- Layers that just pass through to the next layer without transformation.
