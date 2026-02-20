#!/usr/bin/env python3
"""Permission request tracking hook.

Triggered when Claude Code requests permission for a tool use.
Logs permission requests for audit and analysis.
"""

import json
import sys
from datetime import datetime
from pathlib import Path

LOG_DIR = Path(".claudify") / "logs"


def get_log_file():
    """Get the permission log file for today."""
    today = datetime.now().strftime("%Y-%m-%d")
    return LOG_DIR / f"permissions-{today}.log"


def log_permission_request(data: dict):
    """Log permission request to daily log file."""
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    log_file = get_log_file()

    timestamp = datetime.now().isoformat()
    tool_name = data.get("tool_name", "unknown")
    tool_input = data.get("tool_input", {})

    # Extract command if it's a Bash tool
    if tool_name == "Bash":
        command = tool_input.get("command", "")
        entry = f"[{timestamp}] PERMISSION_REQUEST: {tool_name} - {command}\n"
    else:
        entry = f"[{timestamp}] PERMISSION_REQUEST: {tool_name}\n"

    with open(log_file, "a", encoding="utf-8") as f:
        f.write(entry)


def main():
    """Handle permission request event."""
    try:
        data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        print(json.dumps({}))
        return

    # Log the permission request
    log_permission_request(data)

    # Return empty response (allow permission flow to continue)
    print(json.dumps({}))


if __name__ == "__main__":
    main()
