#!/usr/bin/env python3
"""TeammateIdle event hook for agent teams mode.

Triggered when a teammate finishes their current work and becomes idle.
Logs the event for monitoring and optionally suggests next task assignment.

Hook event: TeammateIdle (v2.1.33+)
"""

import json
import sys
from datetime import datetime
from pathlib import Path

LOG_DIR = Path(".claudify") / "logs"


def get_log_file():
    """Get the teammate activity log file for today."""
    today = datetime.now().strftime("%Y-%m-%d")
    return LOG_DIR / f"teammates-{today}.log"


def log_idle(data: dict):
    """Log teammate idle event to daily log file."""
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    log_file = get_log_file()

    timestamp = datetime.now().isoformat()
    teammate_id = data.get("teammate_id", "unknown")
    teammate_name = data.get("teammate_name", "unknown")
    tasks_completed = data.get("tasks_completed", 0)

    entry = (
        f"[{timestamp}] TEAMMATE_IDLE: {teammate_name} ({teammate_id}) "
        f"— {tasks_completed} tasks completed\n"
    )

    with open(log_file, "a", encoding="utf-8") as f:
        f.write(entry)


def main():
    """Handle TeammateIdle event."""
    try:
        data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        print(json.dumps({}))
        return

    log_idle(data)

    # Return empty response (don't interfere with agent teams flow)
    print(json.dumps({}))


if __name__ == "__main__":
    main()
