---
name: pattern-matching
description: This skill should be used when the user asks to "create a new file", "add a function", "write tests", "add error handling", "create an endpoint", or any task where new code should match existing project patterns and conventions.
memory:
  scope: project
---

# Pattern Matching

Ensures new code follows existing project patterns.

## Memory Integration

Before writing new code, check `LEARNINGS.md` for previously recorded patterns in this project. After discovering new patterns, record them:

```
/learn pattern: [description of pattern found]
```

## Triggers

Activate this skill when:
- Creating a new file
- Adding a new function or class
- Writing new tests
- Adding error handling
- Creating API endpoints
- Any new code that should match existing patterns

## Pattern Discovery Process

Before writing new code:

### 1. Find Similar Files
```
Ask: "What existing file is most similar to what I'm creating?"

Search strategy:
- Same directory first
- Same type (if creating a service, find other services)
- Same feature area
```

### 2. Analyze the Pattern
```
From the similar file, extract:
- File structure/organization
- Import ordering
- Naming conventions
- Error handling approach
- Logging patterns
- Test structure
```

### 3. Copy, Don't Invent
```
Use the existing file as a template.
Match it exactly, even if you'd do it differently.
Consistency > Personal preference.
```

## Pattern Checklist

Before committing new code, verify:

### Naming
- [ ] File name follows existing convention (`user_service.py` vs `UserService.py`)
- [ ] Class names match pattern (`UserService` vs `User_Service`)
- [ ] Function names match pattern (`get_user` vs `getUser` vs `GetUser`)
- [ ] Variable names match pattern (`user_id` vs `userId` vs `userID`)
- [ ] Constants match pattern (`MAX_RETRIES` vs `maxRetries`)

### Imports
- [ ] Import order matches (stdlib, third-party, local)
- [ ] Import style matches (`from x import y` vs `import x`)
- [ ] Relative vs absolute imports match existing code

### Structure
- [ ] File organization matches (classes at top? functions at bottom?)
- [ ] Method ordering matches (public first? __init__ first?)
- [ ] Docstring style matches (Google, NumPy, reStructuredText?)

### Error Handling
- [ ] Exception types match (custom exceptions? built-in?)
- [ ] Error messages match style
- [ ] Logging on errors matches pattern

### Testing
- [ ] Test file naming matches (`test_*.py` vs `*_test.py`)
- [ ] Test class naming matches
- [ ] Test method naming matches
- [ ] Fixture usage matches
- [ ] Assertion style matches

## Anti-Pattern Warnings

### ❌ Inventing New Conventions
```python
# Project uses snake_case, but you wrote:
def getUserById(userId):  # Wrong!

# Should be:
def get_user_by_id(user_id):  # Matches project
```

### ❌ Different Error Handling
```python
# Project uses Result types, but you wrote:
def get_user(id):
    if not user:
        raise UserNotFoundError()  # Wrong pattern!

# Should be:
def get_user(id) -> Result[User, Error]:
    if not user:
        return Err(UserNotFoundError())  # Matches project
```

### ❌ Different Test Style
```python
# Project uses pytest fixtures, but you wrote:
class TestUser(unittest.TestCase):  # Wrong pattern!
    def setUp(self):
        self.db = create_test_db()

# Should be:
@pytest.fixture
def db():
    return create_test_db()

def test_get_user(db):  # Matches project
```

## Quick Reference

| Aspect | Question to Ask |
|--------|-----------------|
| Naming | "How are similar things named?" |
| Structure | "How are similar files organized?" |
| Errors | "How do similar functions handle errors?" |
| Tests | "How are similar features tested?" |
| Imports | "How are imports organized in similar files?" |
| Docs | "How are similar things documented?" |

## When Patterns Conflict

If you find conflicting patterns in the codebase:
1. Prefer the pattern in the same directory
2. Prefer the pattern in more recent files
3. Prefer the pattern in files maintained by same author
4. If still unclear, ask the user

## When to Break Patterns

Only break existing patterns when:
1. The user explicitly requests it
2. The existing pattern has a documented bug
3. You're doing a planned refactor of the entire pattern

Even then, document WHY you're deviating.
