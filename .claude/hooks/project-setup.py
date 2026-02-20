#!/usr/bin/env python3
"""One-time project setup hook.

This hook runs once on first session start to initialize
project tracking files and directories. Uses a marker file
to ensure it only runs once.
"""

import json
import sys
from datetime import datetime
from pathlib import Path

# Marker file to track if setup has been completed
SETUP_MARKER = Path(".claude") / ".setup_done"


def create_learnings_file():
    """Create LEARNINGS.md if it doesn't exist."""
    learnings_file = Path("LEARNINGS.md")
    if learnings_file.exists():
        return False

    content = """# Project Learnings

> This file accumulates knowledge over time. Claude reads it each session to avoid repeating mistakes and leverage successful patterns.

## Patterns That Work

<!-- Approaches that have proven successful in this project -->

### Code Patterns
<!-- Successful coding patterns discovered -->
_None documented yet. Use `/learn` to record patterns._

### Testing Patterns
<!-- What works for testing in this project -->
_None documented yet._

### Architecture Patterns
<!-- Structural decisions that work well -->
_None documented yet._

## Mistakes to Avoid

<!-- Things that didn't work - don't repeat these -->

### Failed Approaches
<!-- Approaches that were tried and failed -->
_None documented yet. Use `/learn` to record failures._

### Common Pitfalls
<!-- Gotchas specific to this project -->
_None documented yet._

## Session Insights

<!-- Learnings from specific sessions -->

| Date | Insight | Category | Impact |
|------|---------|----------|--------|
| - | - | - | - |

---

## How Learnings Are Added

**Automatic**: Claude captures learnings via the `auto-learner.py` hook.

**Manual** (optional): Use `/learn` for explicit additions:
- `/learn pattern: [description]` - Record a successful pattern
- `/learn mistake: [description]` - Record something to avoid

---
*This file grows automatically. The more you work on this project, the better Claude performs.*
"""
    learnings_file.write_text(content, encoding="utf-8")
    return True


def create_state_file():
    """Create STATE.md if it doesn't exist."""
    state_file = Path("STATE.md")
    if state_file.exists():
        return False

    today = datetime.now().strftime("%Y-%m-%d %H:%M")
    content = f"""# Project State

> This file is automatically maintained. Claude reads it at session start and updates it during work.

## Current Phase

**Phase:** Initial Setup
**Status:** Project initialized
**Last Updated:** {today}

## Active Tasks

| Task | Status | Notes |
|------|--------|-------|
| - | - | - |

## Completed Tasks

| Task | Date | Files Changed |
|------|------|---------------|
| Project setup | {today[:10]} | Initial configuration |

## Blockers

_None currently._

## Metrics

- **Tests:** Not yet configured
- **Build:** Not yet configured

---
*This file is updated automatically by Claude. Manual edits are preserved.*
"""
    state_file.write_text(content, encoding="utf-8")
    return True


def create_log_directory():
    """Create .claudify/logs directory if it doesn't exist."""
    log_dir = Path(".claudify") / "logs"
    if log_dir.exists():
        return False
    log_dir.mkdir(parents=True, exist_ok=True)
    return True


def mark_setup_complete():
    """Create marker file to prevent re-running setup."""
    SETUP_MARKER.parent.mkdir(parents=True, exist_ok=True)
    SETUP_MARKER.write_text(f"Setup completed: {datetime.now().isoformat()}\n", encoding="utf-8")


def main():
    """Perform one-time project setup."""
    try:
        json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        print(json.dumps({}))
        return

    # Check if setup already completed
    if SETUP_MARKER.exists():
        print(json.dumps({}))
        return

    # Perform setup tasks
    created_files = []

    if create_learnings_file():
        created_files.append("LEARNINGS.md")

    if create_state_file():
        created_files.append("STATE.md")

    if create_log_directory():
        created_files.append(".claudify/logs/")

    # Mark setup as complete
    mark_setup_complete()

    # Output setup summary to stderr (visible to user)
    if created_files:
        print(f"[project-setup] Initialized: {', '.join(created_files)}", file=sys.stderr)
    else:
        print("[project-setup] Project already configured", file=sys.stderr)

    # Return empty response (no interference with session)
    print(json.dumps({}))


if __name__ == "__main__":
    main()
