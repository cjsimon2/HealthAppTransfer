"""
verify-completion.py - Verifies task completion criteria.

Checks that all defined completion criteria for a task are met
before marking it as done, preventing premature closure.
"""

import json
import logging
import os
import sys

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

CRITERIA_FILE = os.path.join(os.environ.get("PROJECT_ROOT", os.getcwd()), ".claude", "completion_criteria.json")


def load_criteria(task_name):
    if not os.path.isfile(CRITERIA_FILE):
        logger.info("No criteria file found at %s. Assuming no criteria.", CRITERIA_FILE)
        return []

    try:
        with open(CRITERIA_FILE, "r", encoding="utf-8") as f:
            all_criteria = json.load(f)
    except (json.JSONDecodeError, IOError) as e:
        logger.error("Failed to load criteria: %s", e)
        return []

    return all_criteria.get(task_name, [])


def main():
    task_name = os.environ.get("HOOK_TASK", "unnamed-task")

    logger.info("Verifying completion criteria for task: %s", task_name)

    criteria = load_criteria(task_name)
    if not criteria:
        logger.info("No completion criteria defined for '%s'. Passing by default.", task_name)
        return 0

    unmet = []
    for criterion in criteria:
        name = criterion.get("name", "unnamed")
        check_type = criterion.get("type", "file_exists")
        target = criterion.get("target", "")

        if check_type == "file_exists":
            if not os.path.exists(target):
                unmet.append(name)
                logger.warning("Criterion NOT met: '%s' (file missing: %s)", name, target)
            else:
                logger.info("Criterion met: '%s'", name)
        else:
            logger.info("Criterion '%s' has unknown type '%s'. Skipping.", name, check_type)

    if unmet:
        logger.error("Task '%s' has %d unmet criterion(a). Cannot mark complete.", task_name, len(unmet))
        return 1

    logger.info("All criteria met for task '%s'.", task_name)
    return 0


if __name__ == "__main__":
    sys.exit(main())
