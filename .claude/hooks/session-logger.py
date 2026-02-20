#!/usr/bin/env python3
"""Log session activity for review and debugging.

This hook logs significant events during the session to help
with debugging and understanding what happened.
"""

import contextlib
import json
import sys
from datetime import datetime
from pathlib import Path


def get_log_file() -> Path:
    """Get the session log file path."""
    log_dir = Path(".claudify") / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)

    # Use date-based log files
    today = datetime.now().strftime("%Y-%m-%d")
    return log_dir / f"session-{today}.log"


def log_event(event_type: str, data: dict) -> None:
    """Log an event to the session log.

    Args:
        event_type: Type of event
        data: Event data
    """
    log_file = get_log_file()

    entry = {
        "timestamp": datetime.now().isoformat(),
        "type": event_type,
        "data": data,
    }

    with open(log_file, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry) + "\n")


def main():
    """Process hook input and log activity."""
    try:
        data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        print(json.dumps({}))
        return

    # Use correct protocol field name
    event_type = data.get("hook_event_name", "unknown")
    session_id = data.get("session_id", "")

    # Log all Stop events (this hook runs on Stop)
    with contextlib.suppress(Exception):
        log_event(
            event_type,
            {
                "session_id": session_id,
                "cwd": data.get("cwd", ""),
                "permission_mode": data.get("permission_mode", ""),
                "stop_hook_active": data.get("stop_hook_active", False),
            },
        )

    # Always return empty response to not interfere
    print(json.dumps({}))


if __name__ == "__main__":
    main()
