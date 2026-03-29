# Parallel Test Analysis

When tests fail, analyze ALL failures simultaneously rather than fixing one at a time.

## Process
1. **Collect all failures.** Run the full test suite and capture every failure message.
2. **Group by root cause.** Many failures often share a single root cause:
   - Model change -> multiple tests that use that model fail.
   - API change -> tests for views, viewmodels, and services all fail.
   - Missing dependency -> all tests in a module fail to compile.
3. **Fix root causes, not symptoms.** One fix can resolve 10+ test failures.
4. **Re-run and repeat.** After fixing a root cause, re-run to see which failures remain.

## Common Root Cause Groups
- **Schema change:** You added/removed a property -> all tests constructing that model fail.
- **Initialization change:** You changed an initializer signature -> all callers fail.
- **Renamed method:** Compiler errors across multiple test files.
- **Behavioral change:** A function returns different data -> assertions fail in multiple tests.
- **Environment missing:** Tests need `modelContainer` or `environment` injected.

## Anti-Pattern: Serial Fixing
Do NOT:
1. See first failure -> fix it -> re-run -> see next failure -> fix it -> re-run...

This is O(n) in re-run time. Parallel analysis is O(1) in re-runs for related failures.

## Tips
- Sort failures by file/module to spot clusters.
- Read compiler errors before runtime failures (fix compilation first).
- If > 50% of tests fail, suspect a foundational change (model, dependency, build config).
