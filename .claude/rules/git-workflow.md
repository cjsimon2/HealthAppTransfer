# Git Workflow Rules

## Git Practices
- Create feature branches for new work
- Write clear, descriptive commit messages
- Keep commits atomic and focused

## Session Management

### Context Checkpoints
At natural break points, update STATE.md (if it exists) with:
- Current subtask progress
- Key decisions made
- Blockers encountered
- Next steps

### Handoff Protocol
When ending a session or hitting context limits:
1. Create/update `handoff.md` with session summary
2. List all changes made with file paths
3. Document any incomplete work
4. Note decisions made and their rationale
5. Provide clear next steps for resumption

### Context Recovery Priority
When resuming work, check sources in this order:
1. `handoff.md` - Most recent session state
2. `STATE.md` - Ongoing project state
3. `git log --oneline -10` - Recent changes
4. `CLAUDE.md` - Project conventions
