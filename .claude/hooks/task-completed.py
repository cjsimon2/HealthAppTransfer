"""
task-completed.py - Updates STATE.md when tasks complete.

Appends a completion entry to STATE.md with the task name,
timestamp, and status.
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
    task_name = os.environ.get("HOOK_TASK", "unnamed-task")
    status = os.environ.get("HOOK_STATUS", "completed")
    timestamp = datetime.now(timezone.utc).isoformat()

    entry = f"\n## Task Completed\n- **Task**: {task_name}\n- **Status**: {status}\n- **Timestamp**: {timestamp}\n"

    logger.info("Recording task completion: %s (%s)", task_name, status)

    if not os.path.isfile(state_file):
        header = "# Project State\n\nAuto-generated state tracking file.\n"
        with open(state_file, "w", encoding="utf-8") as f:
            f.write(header)
        logger.info("Created STATE.md at %s", state_file)

    with open(state_file, "a", encoding="utf-8") as f:
        f.write(entry)

    logger.info("STATE.md updated successfully.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
