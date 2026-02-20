#!/usr/bin/env python3
"""TaskCompleted event hook for agent teams mode.

Triggered when a task transitions to completed status. Logs the event
for metrics collection and post-task analytics.

Hook event: TaskCompleted (v2.1.33+)
"""

import json
import sys
from datetime import datetime
from pathlib import Path

LOG_DIR = Path(".claudify") / "logs"


def get_log_file():
    """Get the task activity log file for today."""
    today = datetime.now().strftime("%Y-%m-%d")
    return LOG_DIR / f"tasks-{today}.log"


def log_completed(data: dict):
    """Log task completion event to daily log file."""
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    log_file = get_log_file()

    timestamp = datetime.now().isoformat()
    task_id = data.get("task_id", "unknown")
    task_subject = data.get("task_subject", "unknown")
    completed_by = data.get("completed_by", "unknown")

    entry = (
        f"[{timestamp}] TASK_COMPLETED: {task_subject} (id={task_id}) "
        f"— completed by {completed_by}\n"
    )

    with open(log_file, "a", encoding="utf-8") as f:
        f.write(entry)


def main():
    """Handle TaskCompleted event."""
    try:
        data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        print(json.dumps({}))
        return

    log_completed(data)

    # Return empty response (don't interfere with agent teams flow)
    print(json.dumps({}))


if __name__ == "__main__":
    main()
