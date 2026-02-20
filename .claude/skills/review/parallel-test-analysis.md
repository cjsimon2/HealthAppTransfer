---
name: parallel-test-analysis
description: Analyze test results in isolation
context: fork
---

# Parallel Test Analysis

Use this skill for isolated analysis of test outputs.

## When to Use

- Analyzing multiple test suites concurrently
- Investigating flaky tests without context pollution
- Comparing test results across different configurations
- Large test suite failure triage

## How It Works

Each analysis runs in an **isolated forked context**:
- Analyzes test output without implementation bias
- Can run multiple analyses concurrently
- Returns focused summary without context bloat
- Fresh perspective on failure patterns

## Usage

After running tests:

```
/parallel-test-analysis tests/unit/ - Analyze unit test results
/parallel-test-analysis tests/integration/ - Analyze integration tests
/parallel-test-analysis --flaky - Identify flaky test patterns
```

## Analysis Focus

### Failure Categorization
- **Environment**: Missing deps, config issues
- **Timing**: Race conditions, timeouts
- **Logic**: Actual bugs in code
- **Test Issues**: Flaky assertions, bad fixtures

### Pattern Detection
- Common failure root causes
- Related test failures (same component)
- Intermittent vs consistent failures

### Priority Assessment
- Which failures block deployment
- Quick wins (easy fixes)
- Requires investigation (complex)

## Output Format

```markdown
## Test Analysis: [suite/path]

### Summary
- Total: X tests
- Passed: Y
- Failed: Z
- Skipped: W

### Failure Analysis
| Test | Category | Root Cause | Fix Priority |
|------|----------|------------|--------------|
| ... | ... | ... | ... |

### Patterns Detected
- [Pattern 1]: Affects tests A, B, C
- [Pattern 2]: Affects tests D, E

### Recommended Actions
1. [Highest priority fix]
2. [Second priority]
3. [Can defer]

### Flaky Test Candidates
- [Test that may be timing-dependent]
```

## Benefits

| Aspect | Sequential Analysis | Parallel Fork |
|--------|---------------------|---------------|
| Speed | Analyze one suite at a time | All suites concurrent |
| Context | Accumulates noise | Clean for each suite |
| Patterns | May miss cross-suite patterns | Fresh detection each time |
