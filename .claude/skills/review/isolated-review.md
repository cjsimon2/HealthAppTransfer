---
name: isolated-review
description: Review code changes with isolated context to avoid bias
context: fork
agent: Explore
---

# Isolated Review

Use this skill for unbiased code review with fresh context.

## When to Use

- Reviewing code you just implemented (avoid self-bias)
- Getting a second opinion on complex changes
- Validating that code is understandable without implementation context
- Security-focused reviews requiring fresh perspective

## How It Works

The review runs in an **isolated forked context**:
- Reviewer sees code without implementation history
- No bias from knowing "what was intended"
- Evaluates code as a new maintainer would see it
- Focuses purely on what's in the diff

## Usage

After implementing changes:

```
/isolated-review path/to/changed/file.py
/isolated-review --diff HEAD~1  # Review last commit
/isolated-review --security     # Security-focused review
```

## Review Focus Areas

### Code Quality
- Is the code self-explanatory?
- Are there obvious bugs or issues?
- Does it follow project conventions?

### Maintainability
- Would a new developer understand this?
- Are there missing comments for complex logic?
- Is the code organization clear?

### Security (when --security flag used)
- OWASP Top 10 vulnerabilities
- Input validation
- Authentication/authorization gaps
- Data exposure risks

## Output Format

```markdown
## Isolated Review: [file/diff]

### First Impressions
- What the code appears to do
- Overall clarity assessment

### Issues Found
| Severity | Location | Issue | Suggestion |
|----------|----------|-------|------------|
| ... | ... | ... | ... |

### Questions
- Things that aren't clear without context
- Potential edge cases to verify

### Verdict
- APPROVE / NEEDS_CHANGES / BLOCKING_ISSUES
```

## Benefits

| Aspect | Standard Review | Isolated Review |
|--------|----------------|-----------------|
| Bias | Implementation context present | Fresh perspective |
| Blind spots | May miss what "should be obvious" | Catches clarity issues |
| Security | May assume safety from intent | Questions everything |
