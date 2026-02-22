#!/usr/bin/env python3
"""Pre-execution safety check for dangerous commands.

This hook checks bash commands before execution to prevent
potentially dangerous operations.
"""

import json
import re
import sys


# Patterns that indicate potentially dangerous commands
# (pattern, reason, guidance) — guidance is injected via additionalContext
DANGEROUS_PATTERNS = [
    (r"rm\s+-rf\s+/", "Recursive delete from root", "Use a targeted path instead of /. Consider moving to trash with `mv` first."),
    (r"rm\s+-rf\s+~", "Recursive delete from home", "Use a specific subdirectory path instead of ~."),
    (r"rm\s+-rf\s+\*", "Recursive delete with wildcard", "List files first with `ls`, then delete specific targets."),
    (r"sudo\s+rm", "Sudo delete operation", "Avoid sudo rm. Use specific paths and confirm with `ls` first."),
    (r">\s*/dev/sd", "Write to disk device", "Do not write directly to block devices."),
    (r"mkfs\.", "Filesystem format command", "Filesystem formatting is destructive and irreversible."),
    (r"dd\s+if=.*of=/dev", "Direct disk write", "dd to block devices is irreversible. Double-check the target device."),
    (r"chmod\s+-R\s+777", "Recursive world-writable permissions", "Use minimal permissions (e.g., 755 for dirs, 644 for files)."),
    (r":()\{\s*:\|:&\s*\};:", "Fork bomb", "This is a fork bomb that will crash the system."),
    (r"curl.*\|\s*bash", "Pipe curl to bash", "Download the script first, review it, then execute."),
    (r"wget.*\|\s*bash", "Pipe wget to bash", "Download the script first, review it, then execute."),
]

# SQL patterns: (pattern, reason, guidance)
SQL_DANGEROUS = [
    (r"DROP\s+TABLE", "SQL DROP TABLE", "Back up the table before dropping. Use DROP TABLE IF EXISTS."),
    (r"DROP\s+DATABASE", "SQL DROP DATABASE", "Back up the database first. This is irreversible."),
    (r"TRUNCATE\s+TABLE", "SQL TRUNCATE", "Consider SELECT COUNT(*) first to verify scope."),
    (r"DELETE\s+FROM.*WHERE\s+1\s*=\s*1", "SQL DELETE all rows", "Use TRUNCATE if you intend to clear the table, or add a specific WHERE clause."),
    (r"DELETE\s+FROM(?!.*WHERE)", "SQL DELETE without WHERE", "Add a WHERE clause to limit the scope of deletion."),
]


def check_command(command: str) -> tuple[bool, str, str]:
    """Check if a command is potentially dangerous.

    Returns:
        Tuple of (is_dangerous, reason, guidance)
    """
    for pattern, reason, guidance in DANGEROUS_PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            return True, reason, guidance

    for pattern, reason, guidance in SQL_DANGEROUS:
        if re.search(pattern, command, re.IGNORECASE):
            return True, reason, guidance

    return False, "", ""


def main():
    """Process hook input and check safety."""
    try:
        data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        print(json.dumps({}))
        return

    # Get command from tool_input (PreToolUse protocol)
    tool_input = data.get("tool_input", {})
    command = tool_input.get("command", "")

    if not command:
        print(json.dumps({}))
        return

    is_dangerous, reason, guidance = check_command(command)

    if is_dangerous:
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": f"Blocked: {reason}",
                "additionalContext": f"Command blocked by safety hook: {reason}. {guidance}",
            }
        }))
    else:
        # Allow the command to proceed
        print(json.dumps({}))


if __name__ == "__main__":
    main()
