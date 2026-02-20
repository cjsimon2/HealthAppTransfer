#!/usr/bin/env python3
"""Auto-learning hook that prompts Claude to capture learnings.

Uses the Stop hook's block mechanism to request learning capture
when significant work has been done in the session.

The hook checks transcript size to estimate if substantial work was done,
then blocks stopping once to request learning capture.
"""

import json
import sys
from pathlib import Path

LEARNINGS_FILE = Path("LEARNINGS.md")
# Minimum transcript size (bytes) to consider "substantial work"
MIN_WORK_THRESHOLD = 50000  # ~50KB of transcript


def learnings_file_exists() -> bool:
    """Check if LEARNINGS.md exists in the project."""
    return LEARNINGS_FILE.exists()


def session_has_substantial_work(transcript_path: str) -> bool:
    """Check if the session has done substantial work worth capturing.

    Uses transcript file size as a heuristic.
    """
    try:
        path = Path(transcript_path)
        if not path.exists():
            return False
        return path.stat().st_size >= MIN_WORK_THRESHOLD
    except Exception:
        return False


def main():
    """Process Stop event and request learning capture if appropriate."""
    try:
        data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        print(json.dumps({}))
        return

    # Prevent infinite loops - don't block if already handling a stop hook
    if data.get("stop_hook_active", False):
        print(json.dumps({}))
        return

    # Only process if LEARNINGS.md exists
    if not learnings_file_exists():
        print(json.dumps({}))
        return

    # Only prompt for substantial sessions
    transcript_path = data.get("transcript_path", "")
    if not session_has_substantial_work(transcript_path):
        print(json.dumps({}))
        return

    # Block stopping to request learning capture
    print(
        json.dumps(
            {
                "decision": "block",
                "reason": (
                    "Before stopping, briefly check if this session produced insights worth "
                    "preserving in LEARNINGS.md. If you discovered a pattern, gotcha, or "
                    "codebase insight, add a one-line bullet. If nothing notable, proceed to stop."
                ),
            }
        )
    )


if __name__ == "__main__":
    main()
