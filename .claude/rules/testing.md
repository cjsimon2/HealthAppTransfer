# Testing Rules

## Testing Guidelines
- Write tests for new functionality
- Ensure existing tests pass before committing
- Test edge cases and error conditions

## 5-Step Verification Sequence
1. **Build/Compile**: Does the code compile without errors?
2. **Tests Pass**: Do existing tests still pass?
3. **Feature Works**: Does the new functionality work?
4. **No Regressions**: Does old functionality still work?
5. **Acceptance Met**: Are all acceptance criteria satisfied?

## 3-Attempt Verification Loop
When a test or build fails:

```
Attempt 1: Fix the specific error reported
           ↓ Still failing?
Attempt 2: Re-read context, try a different approach
           ↓ Still failing?
Attempt 3: STOP. Document the blocker. Escalate.
```

After 3 failed attempts, do NOT keep trying the same thing. Document:
- What was tried
- What failed
- What context might be missing
