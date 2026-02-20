# Refactoring

Identify refactoring opportunities and apply improvements.

## Refactoring Patterns

### Extract Function
Move repeated code into a reusable function.

### Extract Variable
Name complex expressions for clarity.

### Rename
Improve names for clarity.

### Simplify Conditionals
Reduce nested if/else with early returns or guard clauses.

### Remove Duplication
Consolidate repeated logic.

### Split Large Functions
Break down functions doing too much.

## Usage
Specify what to refactor: `/refactor src/utils.py`
Or describe the refactoring: `/refactor extract auth logic into separate module`

## Guidelines
- Make small, incremental changes
- Ensure tests pass after each change
- Commit frequently
- Don't change behavior while refactoring
