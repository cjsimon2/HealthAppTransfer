# Test Generation

Generate tests for existing code.

## Test Types

### Unit Tests
Test individual functions and methods in isolation.

### Integration Tests
Test how components work together.

### Edge Cases
Test boundary conditions and error cases.

## Instructions

1. Analyze the code to understand its behavior
2. Identify testable units
3. Generate tests covering:
   - Happy path
   - Error conditions
   - Edge cases
   - Boundary values

## Usage
`/test-generate src/utils.py` - Generate tests for file
`/test-generate src/auth/` - Generate tests for module

## Guidelines
- Follow project's testing framework conventions
- Use meaningful test names
- Test one thing per test
- Include both positive and negative cases
- Mock external dependencies
