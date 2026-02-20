---
name: session-teleport
description: This skill should be used when the user asks to "teleport session", "move to web", "open in browser", "continue on web", or wants to move their CLI session to the claude.ai/code web interface.
env:
  session_id: ${CLAUDE_SESSION_ID}
---

# Session Teleportation

Move your current Claude Code CLI session to the claude.ai/code web interface for continued interaction.

## When to Use

- **Complex visualization**: Need to see diagrams, charts, or formatted output better
- **Long-running tasks**: Want to continue work in a browser tab while doing other terminal work
- **Sharing**: Need to share your session with someone who prefers the web interface
- **Mobile access**: Continue work from a mobile device

## How to Teleport

Use the built-in `/teleport` command in Claude Code:

```
/teleport
```

This generates a unique URL that opens your current session context in the claude.ai/code web interface.

## Session Identification

Current session ID: `${CLAUDE_SESSION_ID}`

This ID uniquely identifies the current Claude Code session and is available as an environment variable. It can be used for logging, tracking, and correlating activity across hooks and skills.

## What Gets Transferred

- Full conversation history
- Current project context
- File references and code snippets
- Tool execution history

## Limitations

- One-way transfer (web to CLI requires starting fresh)
- Session URL expires after 24 hours
- Some CLI-specific features may behave differently in web

## Best Practices

1. **Save your work first**: Commit any pending changes before teleporting
2. **Note the URL**: The generated URL is shown only once
3. **Check context**: Review what context is being transferred
4. **Close CLI session**: The CLI session remains active but may conflict if both are used simultaneously

## Example Workflow

```
# In terminal, working on a complex feature
/teleport

# Copy the URL and open in browser
# Continue work in claude.ai/code with better visualization
# Come back to CLI later with a fresh session if needed
```
