# Code Review

Perform a thorough code review of recent changes or specified files.

## Review Focus Areas

### Correctness
- Does the code do what it's supposed to?
- Are there any logic errors?
- Are edge cases handled?

### Readability
- Is the code easy to understand?
- Are names descriptive?
- Is the structure clear?

### Maintainability
- Is the code modular?
- Are there any code smells?
- Would a new developer understand this?

### Performance
- Any obvious performance issues?
- Unnecessary computations?
- Memory leaks?

### Security
- Input validation?
- Authentication/authorization checks?
- Sensitive data handling?

## Usage
Specify files to review: `/review src/auth.py`
Or review recent changes: `/review`
