"""
state-tracker.py - Auto-updates STATE.md.

Periodically writes the current project state summary to STATE.md,
including active tasks, recent changes, and session info.
"""

import logging
import os
import sys
from datetime import datetime, timezone

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


def main():
    project_root = os.environ.get("PROJECT_ROOT", os.getcwd())
    state_file = os.path.join(project_root, "STATE.md")
    session_id = os.environ.get("HOOK_SESSION_ID", "unknown")
    current_task = os.environ.get("HOOK_CURRENT_TASK", "none")
    timestamp = datetime.now(timezone.utc).isoformat()

    state_entry = (
        f"\n## State Update\n"
        f"- **Session**: {session_id}\n"
        f"- **Current Task**: {current_task}\n"
        f"- **Updated At**: {timestamp}\n"
    )

    logger.info("Updating state: session=%s task=%s", session_id, current_task)

    if not os.path.isfile(state_file):
        header = "# Project State\n\nAuto-generated state tracking file.\n"
        with open(state_file, "w", encoding="utf-8") as f:
            f.write(header)
        logger.info("Created STATE.md at %s", state_file)

    with open(state_file, "a", encoding="utf-8") as f:
        f.write(state_entry)

    logger.info("STATE.md updated.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
