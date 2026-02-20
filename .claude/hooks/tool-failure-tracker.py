#!/usr/bin/env python3
"""Post-tool failure hook to log tool execution failures.

This hook fires when a tool execution fails (PostToolUseFailure event).
It logs failures to .claudify/logs/ for debugging and analysis.
"""

import json
import sys
from datetime import datetime
from pathlib import Path

LOG_DIR = Path(".claudify/logs")


def get_log_file() -> Path:
    """Get the log file path for today."""
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    date_str = datetime.now().strftime("%Y-%m-%d")
    return LOG_DIR / f"tool-failures-{date_str}.log"


def main():
    """Process hook input and log tool failure."""
    try:
        data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        print(json.dumps({}))
        return

    tool_name = data.get("tool_name", "unknown")
    tool_input = data.get("tool_input", {})
    tool_response = data.get("tool_response", {})

    # Extract command for Bash tools
    command = tool_input.get("command", "") if isinstance(tool_input, dict) else ""

    # Extract error info from response
    error_msg = ""
    if isinstance(tool_response, dict):
        for field in ("stderr", "error", "message", "content"):
            if field in tool_response:
                val = tool_response[field]
                if isinstance(val, str) and val:
                    error_msg = val[:500]  # Truncate long errors
                    break
    elif isinstance(tool_response, str):
        error_msg = tool_response[:500]

    # Log the failure
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = {
        "timestamp": timestamp,
        "tool": tool_name,
        "command": command[:200] if command else None,
        "error": error_msg if error_msg else None,
    }
    # Remove None values
    log_entry = {k: v for k, v in log_entry.items() if v is not None}

    try:
        log_file = get_log_file()
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(json.dumps(log_entry) + "\n")
    except (PermissionError, OSError) as e:
        print(f"[tool-failure-tracker] Cannot write log: {e}", file=sys.stderr)

    print(json.dumps({}))


if __name__ == "__main__":
    main()
