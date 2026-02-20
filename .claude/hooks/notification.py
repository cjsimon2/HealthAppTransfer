#!/usr/bin/env python3
"""Notification event tracking hook.

Triggered on various notification events:
- permission_prompt: User was prompted for permission
- idle_prompt: Agent became idle
- task_complete: A task was completed
- error: An error occurred

Logs notifications for analytics and debugging.
"""

import json
import sys
from datetime import datetime
from pathlib import Path

LOG_DIR = Path(".claudify") / "logs"


def get_log_file():
    """Get the notification log file for today."""
    today = datetime.now().strftime("%Y-%m-%d")
    return LOG_DIR / f"notifications-{today}.log"


def log_notification(data: dict):
    """Log notification to daily log file."""
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    log_file = get_log_file()

    timestamp = datetime.now().isoformat()
    notification_type = data.get("type", "unknown")
    message = data.get("message", "")

    # Format based on notification type
    if notification_type == "permission_prompt":
        entry = f"[{timestamp}] NOTIFICATION: permission_prompt - awaiting user response\n"
    elif notification_type == "idle_prompt":
        entry = f"[{timestamp}] NOTIFICATION: idle_prompt - agent idle\n"
    elif notification_type == "task_complete":
        entry = f"[{timestamp}] NOTIFICATION: task_complete - {message}\n"
    elif notification_type == "error":
        entry = f"[{timestamp}] NOTIFICATION: error - {message}\n"
    else:
        entry = f"[{timestamp}] NOTIFICATION: {notification_type} - {message}\n"

    with open(log_file, "a", encoding="utf-8") as f:
        f.write(entry)


def main():
    """Handle notification event."""
    try:
        data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        print(json.dumps({}))
        return

    # Log the notification
    log_notification(data)

    # Return empty response (don't interfere with notification flow)
    print(json.dumps({}))


if __name__ == "__main__":
    main()
