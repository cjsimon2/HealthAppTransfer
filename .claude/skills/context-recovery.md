# Context Recovery

When context is lost mid-session (e.g., after a long tangent or confusion), recover using this protocol.

## Step 1: Read CLAUDE.md
- Grounds you in the project's conventions, architecture, and rules.
- Reminds you of tech stack, naming patterns, and constraints.

## Step 2: Read STATE.md
- Shows the current phase and active tasks.
- Clarifies what you should be working on right now.
- Reveals blockers and dependencies.

## Step 3: Review Recent Changes
```bash
git diff
git diff --cached
git log --oneline -10
```
- `git diff` shows unstaged work in progress.
- `git diff --cached` shows staged but uncommitted work.
- `git log` shows the last 10 commits for trajectory.

## Step 4: Re-Anchor to the Current Task
- Identify the specific task from STATE.md.
- Re-read its acceptance criteria.
- Review the files you were editing (check `git diff --name-only`).

## When to Use This
- You've gone down a rabbit hole and lost track of the goal.
- An unexpected error derailed your focus.
- You're unsure if a change you're about to make aligns with the plan.
- You've been context-switched and need to return to this project.

## Key Principle
It is faster to spend 30 seconds recovering context than to spend 10 minutes working in the wrong direction.
