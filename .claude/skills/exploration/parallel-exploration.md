---
name: parallel-exploration
description: Explore codebase sections in parallel with isolated context
context: fork
agent: Explore
---

# Parallel Exploration

Use this skill for parallel codebase analysis on large projects (>50 files).

## When to Use

- Exploring multiple directories concurrently
- Analyzing unrelated subsystems simultaneously
- Large codebase initial discovery
- Finding patterns across isolated components

## How It Works

Each exploration runs in an **isolated forked context**:
- Fresh context without parent session contamination
- Returns a summary without polluting main context
- Prevents context overflow on large projects

## Usage

Invoke via skill when the project has many files and you need to explore multiple areas:

```
/parallel-exploration src/components - Analyze React components
/parallel-exploration src/api - Analyze API layer
/parallel-exploration src/utils - Analyze utilities
```

## Output Format

Each forked exploration returns:

```markdown
## Exploration Summary: [directory]

### Structure
- Key files and their purposes
- Directory organization patterns

### Patterns Found
- Common conventions observed
- Design patterns in use

### Key Insights
- Important architectural decisions
- Notable implementations

### Relevant to Task
- Files that may need modification
- Interfaces to be aware of
```

## Benefits

| Metric | Sequential | Parallel Fork |
|--------|------------|---------------|
| Context Usage | Full accumulation | Isolated per fork |
| Speed | Linear | Concurrent |
| Bias | Accumulated | Fresh each time |
