#!/usr/bin/env python3
"""Pre-execution safety check for dangerous commands.

This hook checks bash commands before execution to prevent
potentially dangerous operations. Uses the hookSpecificOutput
PreToolUse schema (v2.1.9+) for all decisions: deny dangerous
commands, allow safe ones with optional additionalContext.
"""

import json
import re
import sys

# Patterns that indicate potentially dangerous commands
DANGEROUS_PATTERNS = [
    (r"rm\s+-rf\s+/", "Recursive delete from root"),
    (r"rm\s+-rf\s+~", "Recursive delete from home"),
    (r"rm\s+-rf\s+\*", "Recursive delete with wildcard"),
    (r"sudo\s+rm", "Sudo delete operation"),
    (r">\s*/dev/sd", "Write to disk device"),
    (r"mkfs\.", "Filesystem format command"),
    (r"dd\s+if=.*of=/dev", "Direct disk write"),
    (r"chmod\s+-R\s+777", "Recursive world-writable permissions"),
    (r":()\{\s*:\|:&\s*\};:", "Fork bomb"),
    (r"curl.*\|\s*bash", "Pipe curl to bash"),
    (r"wget.*\|\s*bash", "Pipe wget to bash"),
]

# SQL patterns
SQL_DANGEROUS = [
    (r"DROP\s+TABLE", "SQL DROP TABLE"),
    (r"DROP\s+DATABASE", "SQL DROP DATABASE"),
    (r"TRUNCATE\s+TABLE", "SQL TRUNCATE"),
    (r"DELETE\s+FROM.*WHERE\s+1\s*=\s*1", "SQL DELETE all rows"),
    (r"DELETE\s+FROM(?!.*WHERE)", "SQL DELETE without WHERE"),
]

# Patterns that warrant safety context (not blocked, but noted)
CAUTION_PATTERNS = [
    (r"rm\s+-r", "Recursive delete — verify target path is correct"),
    (r"git\s+reset\s+--hard", "Hard reset discards uncommitted changes"),
    (r"git\s+push\s+.*--force", "Force push rewrites remote history"),
    (r"git\s+clean\s+-[fd]", "Git clean permanently removes untracked files"),
    (r"pip\s+install\s+(?!-r\b)(?!--)", "Installing package — verify source is trusted"),
    (r"npm\s+install\s+(?!--save-dev)", "Installing package — verify source is trusted"),
    (r"chmod\s+", "Changing file permissions"),
    (r"docker\s+rm", "Removing Docker container"),
    (r"docker\s+system\s+prune", "Docker prune removes unused data"),
]


def _make_output(
    decision: str,
    reason: str = "",
    context: str = "",
) -> dict:
    """Build a hookSpecificOutput dict for PreToolUse (v2.1.9+ schema).

    Args:
        decision: "allow", "deny", or "ask"
        reason: Explanation for the decision
        context: Additional context injected into Claude's prompt
    """
    output: dict = {
        "hookEventName": "PreToolUse",
        "permissionDecision": decision,
    }
    if reason:
        output["permissionDecisionReason"] = reason
    if context:
        output["additionalContext"] = context
    return {"hookSpecificOutput": output}


def check_command(command: str) -> tuple[bool, str]:
    """Check if a command is potentially dangerous.

    Args:
        command: The command to check

    Returns:
        Tuple of (is_dangerous, reason)
    """
    # Check bash patterns
    for pattern, reason in DANGEROUS_PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            return True, reason

    # Check SQL patterns
    for pattern, reason in SQL_DANGEROUS:
        if re.search(pattern, command, re.IGNORECASE):
            return True, reason

    return False, ""


def get_caution_context(command: str) -> str | None:
    """Get safety context for commands that warrant a caution note.

    Args:
        command: The command to check

    Returns:
        Caution message or None if no caution needed
    """
    notes = []
    for pattern, note in CAUTION_PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            notes.append(note)
    if notes:
        return "Safety note: " + "; ".join(notes)
    return None


def main():
    """Process hook input and check safety."""
    try:
        data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, ValueError):
        print(json.dumps({}))
        return

    # Get command from tool_input (PreToolUse protocol)
    tool_input = data.get("tool_input", {})
    command = tool_input.get("command", "")

    if not command:
        print(json.dumps({}))
        return

    is_dangerous, reason = check_command(command)

    if is_dangerous:
        result = _make_output(
            decision="deny",
            reason=f"Potentially dangerous command blocked: {reason}",
        )
    else:
        caution = get_caution_context(command)
        if caution:
            result = _make_output(
                decision="allow",
                reason="Command allowed with safety note",
                context=caution,
            )
        else:
            result = _make_output(decision="allow")

    print(json.dumps(result))


if __name__ == "__main__":
    main()
