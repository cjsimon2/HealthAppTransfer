# Code Quality Rules

## Anti-Overengineering Framework

Before adding any abstraction, helper, or "improvement", ask:

```
Will this code need this feature in the next 2 weeks?
├── YES → Implement it
└── NO → Don't implement it
```

### Pattern Analysis Checklist
- [ ] Is there existing code doing something similar? → Copy its pattern
- [ ] Am I adding a helper for a one-time use? → Don't
- [ ] Am I making this "configurable" for no current need? → Don't
- [ ] Am I adding error handling for impossible scenarios? → Don't
- [ ] Would a junior developer understand this in 5 minutes? → If no, simplify

### NEVER Do These
- Create abstractions for single-use code
- Add "just in case" parameters or configurations
- Build factory patterns without multiple concrete implementations
- Add backwards-compatibility shims when you can just change the code
- Write defensive code against impossible states

### ALWAYS Do These
- Copy existing patterns before inventing new ones
- Write the simplest code that works
- Delete code instead of commenting it out
- Use concrete types unless polymorphism is actually needed

## Code Style
- Follow existing patterns in the codebase
- Keep functions focused and small
- Write self-documenting code with clear names
- Add comments only where logic isn't self-evident
