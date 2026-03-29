"""
teammate-idle.py - Detects idle teammates.

Monitors teammate activity timestamps and flags any teammate
that has been idle beyond a configurable threshold.
"""

import json
import logging
import os
import sys
import time

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

IDLE_THRESHOLD_SECONDS = int(os.environ.get("IDLE_THRESHOLD", "300"))
ACTIVITY_FILE = os.path.join(os.environ.get("PROJECT_ROOT", os.getcwd()), ".claude", "teammate_activity.json")


def main():
    logger.info("Checking for idle teammates (threshold: %ds)", IDLE_THRESHOLD_SECONDS)

    if not os.path.isfile(ACTIVITY_FILE):
        logger.info("No teammate activity file found at %s. Nothing to check.", ACTIVITY_FILE)
        return 0

    try:
        with open(ACTIVITY_FILE, "r", encoding="utf-8") as f:
            activities = json.load(f)
    except (json.JSONDecodeError, IOError) as e:
        logger.error("Failed to read activity file: %s", e)
        return 1

    now = time.time()
    idle_teammates = []

    for teammate, last_active in activities.items():
        elapsed = now - last_active
        if elapsed > IDLE_THRESHOLD_SECONDS:
            idle_teammates.append((teammate, elapsed))
            logger.warning("Teammate '%s' idle for %.0f seconds.", teammate, elapsed)

    if idle_teammates:
        logger.info("Detected %d idle teammate(s).", len(idle_teammates))
    else:
        logger.info("All teammates are active.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
