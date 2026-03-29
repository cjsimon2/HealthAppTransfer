"""
session-logger.py - Logs session activity.

Maintains a running log of session events including start, stop,
and significant actions for auditing and debugging.
"""

import json
import logging
import os
import sys
from datetime import datetime, timezone

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

SESSION_LOG = os.path.join(os.environ.get("PROJECT_ROOT", os.getcwd()), ".claude", "session_log.json")


def main():
    event_type = os.environ.get("HOOK_EVENT", "generic")
    session_id = os.environ.get("HOOK_SESSION_ID", "unknown")
    details = os.environ.get("HOOK_DETAILS", "")

    entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "session_id": session_id,
        "event": event_type,
        "details": details[:1000],
    }

    logger.info("Session event: session=%s event=%s", session_id, event_type)

    log_entries = []
    if os.path.isfile(SESSION_LOG):
        try:
            with open(SESSION_LOG, "r", encoding="utf-8") as f:
                log_entries = json.load(f)
        except (json.JSONDecodeError, IOError):
            log_entries = []

    log_entries.append(entry)

    os.makedirs(os.path.dirname(SESSION_LOG), exist_ok=True)
    with open(SESSION_LOG, "w", encoding="utf-8") as f:
        json.dump(log_entries, f, indent=2)

    logger.info("Session event logged. Total events: %d", len(log_entries))
    return 0


if __name__ == "__main__":
    sys.exit(main())
