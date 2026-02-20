# Learn - Capture Project Knowledge

Record learnings, patterns, and insights that should persist across sessions.

## Usage

```
/learn pattern: [description of what works]
/learn mistake: [description of what to avoid]
/learn insight: [codebase knowledge or discovery]
/learn decision: [important decision and rationale]
```

Or just describe what you learned:
```
/learn The API returns paginated results, need to handle nextToken
/learn Using factory pattern here was overkill, simple function works better
```

## Categories

### Patterns That Work
Successful approaches worth repeating:
- Code patterns that solved problems elegantly
- Testing strategies that caught bugs
- Architecture decisions that scaled well
- Workflows that improved productivity

### Mistakes to Avoid
Things that didn't work:
- Approaches that failed or caused issues
- Anti-patterns discovered in this codebase
- Assumptions that turned out wrong
- Time-wasting rabbit holes

### Codebase Insights
Deep knowledge about this specific project:
- How key abstractions work
- Non-obvious integration points
- Performance gotchas
- Dependency quirks

### Decisions
Important choices and their rationale:
- Why certain approaches were chosen
- Trade-offs that were considered
- Context that future sessions need

## Instructions

1. Parse the user's input to identify:
   - Category (pattern/mistake/insight/decision)
   - Description of the learning
   - Any relevant context

2. Read the current LEARNINGS.md file

3. Add the learning to the appropriate section:
   - Format as a bullet point with date
   - Include enough context to be useful later
   - Link to relevant files if applicable

4. Write the updated LEARNINGS.md

5. Confirm what was recorded

## Output Format

After recording:

```markdown
## Learning Recorded

**Category:** [Pattern/Mistake/Insight/Decision]
**Added to:** LEARNINGS.md

### What was captured:
[The learning in clear, actionable format]

### Why this matters:
[Brief explanation of how this helps future sessions]
```

## Examples

**Input:** `/learn pattern: Using `pytest.mark.parametrize` for edge cases is much cleaner than separate test functions`

**Output:**
```markdown
## Learning Recorded

**Category:** Pattern
**Added to:** LEARNINGS.md → Testing Patterns

### What was captured:
- Use `pytest.mark.parametrize` for edge case testing instead of separate test functions - cleaner and more maintainable

### Why this matters:
Future test writing will follow this pattern, leading to more consistent and readable tests.
```

## Auto-Detection

If no category is specified, infer from keywords:
- "works", "better", "cleaner", "solved" → Pattern
- "failed", "broke", "avoid", "don't" → Mistake
- "discovered", "found", "realized", "actually" → Insight
- "decided", "chose", "because", "trade-off" → Decision
