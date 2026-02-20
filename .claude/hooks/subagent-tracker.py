#!/usr/bin/env python3
"""Track subagent lifecycle for parallel build monitoring.

This hook logs when subagents start and stop, providing visibility into
parallel agent activity during autonomous builds. Useful for debugging,
performance analysis, and understanding how Claude orchestrates work.

Hook events handled:
- SubagentStart: Fires when a subagent is spawned (via Task tool)
- SubagentStop: Fires when a subagent finishes execution
"""

import contextlib
import json
import sys
from datetime import datetime
from pathlib import Path


def get_log_file() -> Path:
    """Get the subagent activity log file path."""
    log_dir = Path(".claudify") / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)

    # Use date-based log files
    today = datetime.now().strftime("%Y-%m-%d")
    return log_dir / f"subagents-{today}.log"


def log_event(event_type: str, data: dict) -> None:
    """Log a subagent event.

    Args:
        event_type: Type of event (SubagentStart or SubagentStop)
        data: Event data
    """
    log_file = get_log_file()

    entry = {
        "timestamp": datetime.now().isoformat(),
        "event": event_type,
        "data": data,
    }

    with open(log_file, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry) + "\n")


def handle_subagent_start(data: dict) -> None:
    """Handle SubagentStart event - log when a subagent is spawned."""
    agent_id = data.get("agent_id", "unknown")
    agent_type = data.get("agent_type", "unknown")
    session_id = data.get("session_id", "")

    with contextlib.suppress(Exception):
        log_event(
            "SubagentStart",
            {
                "agent_id": agent_id,
                "agent_type": agent_type,
                "session_id": session_id,
                "cwd": data.get("cwd", ""),
            },
        )

    # Print to stderr for visibility (non-blocking)
    print(f"[subagent-tracker] Started: {agent_type} ({agent_id})", file=sys.stderr)

    # Allow the subagent to start
    print(json.dumps({}))


def handle_subagent_stop(data: dict) -> None:
    """Handle SubagentStop event - log when a subagent finishes."""
    # Check for hook loop prevention
    if data.get("stop_hook_active", False):
        print(json.dumps({}))
        return

    agent_id = data.get("agent_id", "unknown")
    session_id = data.get("session_id", "")
    agent_transcript_path = data.get("agent_transcript_path", "")

    # Optionally read subagent output stats
    output_lines = 0
    if agent_transcript_path:
        with contextlib.suppress(Exception):
            transcript_path = Path(agent_transcript_path).expanduser()
            if transcript_path.exists():
                with open(transcript_path, encoding="utf-8") as f:
                    output_lines = sum(1 for _ in f)

    with contextlib.suppress(Exception):
        log_event(
            "SubagentStop",
            {
                "agent_id": agent_id,
                "session_id": session_id,
                "transcript_path": agent_transcript_path,
                "output_lines": output_lines,
            },
        )

    # Print to stderr for visibility (non-blocking)
    print(
        f"[subagent-tracker] Stopped: {agent_id} ({output_lines} transcript lines)", file=sys.stderr
    )

    # Allow the stop
    print(json.dumps({}))


def main():
    """Route to appropriate handler based on hook event."""
    try:
        data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        print(json.dumps({}))
        return

    event_name = data.get("hook_event_name", "")

    if event_name == "SubagentStart":
        handle_subagent_start(data)
    elif event_name == "SubagentStop":
        handle_subagent_stop(data)
    else:
        # Unknown event, allow
        print(json.dumps({}))


if __name__ == "__main__":
    main()
