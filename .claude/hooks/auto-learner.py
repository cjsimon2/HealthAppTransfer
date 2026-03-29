"""
auto-learner.py - Records learnings to LEARNINGS.md.

Captures insights, patterns, and lessons learned during sessions
and appends them to a persistent LEARNINGS.md file for future reference.
"""

import logging
import os
import sys
from datetime import datetime, timezone

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


def main():
    project_root = os.environ.get("PROJECT_ROOT", os.getcwd())
    learnings_file = os.path.join(project_root, "LEARNINGS.md")
    learning = os.environ.get("HOOK_LEARNING", "")
    category = os.environ.get("HOOK_CATEGORY", "General")
    session_id = os.environ.get("HOOK_SESSION_ID", "unknown")
    timestamp = datetime.now(timezone.utc).isoformat()

    if not learning:
        logger.info("No learning provided. Nothing to record.")
        return 0

    entry = (
        f"\n## {category}\n"
        f"- **Learned**: {learning}\n"
        f"- **Session**: {session_id}\n"
        f"- **Recorded At**: {timestamp}\n"
    )

    logger.info("Recording learning: category=%s session=%s", category, session_id)

    if not os.path.isfile(learnings_file):
        header = "# Learnings\n\nAuto-captured learnings from Claude Code sessions.\n"
        with open(learnings_file, "w", encoding="utf-8") as f:
            f.write(header)
        logger.info("Created LEARNINGS.md at %s", learnings_file)

    with open(learnings_file, "a", encoding="utf-8") as f:
        f.write(entry)

    logger.info("Learning recorded to LEARNINGS.md.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
