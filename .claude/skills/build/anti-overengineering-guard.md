---
name: anti-overengineering-guard
description: This skill should be used when about to create abstractions, interfaces, base classes, factory patterns, builder patterns, strategy patterns, or when making something "configurable" or "extensible". Prevents unnecessary complexity and scope creep.
---

# Anti-Overengineering Guard

Prevents unnecessary complexity and scope creep.

## Triggers

Activate this skill when you're about to:
- Create a new abstraction, interface, or base class
- Add a factory, builder, or strategy pattern
- Make something "configurable" or "extensible"
- Create a helper function or utility class
- Add parameters "for flexibility"
- Write "defensive" error handling

## The 2-Week Decision Framework

Before adding ANY abstraction or complexity, ask:

```
Will this code need this feature in the next 2 weeks?
│
├── YES, and I can point to the specific requirement
│   └── ✅ Implement it
│
├── MAYBE, it might be useful someday
│   └── ❌ Don't implement it
│
└── NO, but it's "good practice"
    └── ❌ Don't implement it
```

## Warning Signs Table

| You're thinking... | Reality check |
|-------------------|---------------|
| "Let's make this configurable" | Is there a second configuration? |
| "We might need to extend this" | Do we have a second implementation now? |
| "This could be reused" | Will it be reused in 2 weeks? |
| "Let's add a factory" | Are there multiple concrete types today? |
| "Better to be defensive" | Can this error actually happen? |
| "Let's abstract this" | Is there variation to abstract over? |

## Good vs Bad Examples

### ❌ BAD: Premature Abstraction
```python
# Over-engineered for one use case
class UserServiceFactory:
    def create_service(self, config: ServiceConfig) -> UserServiceInterface:
        if config.type == "default":
            return DefaultUserService(config)
        raise ValueError(f"Unknown type: {config.type}")

# Used exactly once:
service = UserServiceFactory().create_service(ServiceConfig(type="default"))
```

### ✅ GOOD: Direct Implementation
```python
# Simple and clear
user_service = UserService(db_connection)
```

### ❌ BAD: Defensive Coding for Impossible States
```python
def get_user(user_id: int) -> User:
    if user_id is None:  # Can't happen - type says int
        raise ValueError("user_id cannot be None")
    if not isinstance(user_id, int):  # Can't happen - type checked
        raise TypeError("user_id must be int")
    # ... actual logic
```

### ✅ GOOD: Trust Your Types
```python
def get_user(user_id: int) -> User:
    return db.query(User).get(user_id)
```

### ❌ BAD: "Flexible" Parameters
```python
def send_email(
    to: str,
    subject: str,
    body: str,
    cc: Optional[List[str]] = None,  # Never used
    bcc: Optional[List[str]] = None,  # Never used
    reply_to: Optional[str] = None,  # Never used
    priority: str = "normal",  # Never used
    track_opens: bool = False,  # Never used
):
```

### ✅ GOOD: What's Actually Needed
```python
def send_email(to: str, subject: str, body: str):
```

## Self-Check Questions

Before committing code, ask yourself:

1. **Did I add any code "just in case"?** → Remove it
2. **Did I create an abstraction with one implementation?** → Use concrete type
3. **Did I add parameters that have one value?** → Remove them
4. **Did I handle errors that can't happen?** → Remove that handling
5. **Did I copy a pattern without needing the flexibility it provides?** → Simplify

## When Abstraction IS Appropriate

Abstraction is justified when:
- You have 2+ concrete implementations TODAY (not "someday")
- The abstraction removes duplication that EXISTS (not predicted)
- External requirements mandate it (interface contract, plugin system)
- Testing requires it (dependency injection for mocks)

Even then, prefer the simplest abstraction that works.
