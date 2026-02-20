#!/usr/bin/env python3
"""Monitor context usage and prompt handoff when context is high.

This hook uses THREE strategies (in priority order):
1. context_window payload (v2.1.6+): Direct used_percentage from hook event data
2. PreCompact hook (reliable): Triggers when Claude is about to compact (~78%)
3. Stop hook (transcript fallback): Reads actual token usage from transcript JSONL

The context_window object (v2.1.6+) provides used_percentage, remaining_tokens,
and total_tokens directly in the hook payload. When available, this is preferred
over transcript parsing.

Research sources:
- https://codelynx.dev/posts/calculate-claude-code-context
- https://github.com/anthropics/claude-code/issues/13783
- Hooks reference: https://code.claude.com/docs/en/hooks
"""

import json
import sys
from pathlib import Path

# Claude's context window (Opus 4.5 / Sonnet 4.5 have 200K)
MAX_CONTEXT_TOKENS = 200000

# Threshold for Stop hook warning (70% = before compaction at 78%)
STOP_HOOK_THRESHOLD = 0.70


def get_context_from_payload(data: dict) -> tuple[int | None, float | None]:
    """Extract context usage from the hook event payload (v2.1.6+).

    The context_window object provides used_percentage directly when available.

    Returns:
        Tuple of (token_count, percentage) or (None, None) if unavailable.
    """
    ctx = data.get("context_window")
    if not isinstance(ctx, dict):
        return None, None

    used_pct = ctx.get("used_percentage")
    if used_pct is None:
        return None, None

    total = ctx.get("total_tokens", MAX_CONTEXT_TOKENS)
    remaining = ctx.get("remaining_tokens")

    if remaining is not None and total:
        tokens = total - remaining
    else:
        tokens = int(total * used_pct / 100) if total else None

    return tokens, used_pct / 100


def get_context_from_transcript(transcript_path: str) -> tuple[int | None, float | None]:
    """
    Get actual context usage from transcript's most recent valid entry.

    The transcript JSONL contains actual API token counts in message.usage.
    We read the MOST RECENT entry that has usage data (not cumulative sums).

    Returns:
        Tuple of (token_count, percentage) or (None, None) if unavailable.
    """
    path = Path(transcript_path).expanduser()

    if not path.exists():
        return None, None

    try:
        latest_usage = None

        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue

                try:
                    data = json.loads(line)
                except json.JSONDecodeError:
                    continue

                # Skip entries without usage data
                message = data.get("message", {})
                if not isinstance(message, dict):
                    continue

                usage = message.get("usage")
                if not usage:
                    continue

                # Skip sidechain entries (subagent conversations)
                if data.get("isSidechain") is True:
                    continue

                # Skip error messages
                if data.get("isApiErrorMessage") is True:
                    continue

                # This is a valid entry - store it (we want the latest)
                latest_usage = usage

        if not latest_usage:
            return None, None

        # Calculate total context tokens
        # input_tokens = prompt tokens in current context
        # cache_read_input_tokens = tokens read from cache (still in context)
        # cache_creation_input_tokens = tokens written to cache (still in context)
        total_tokens = (
            latest_usage.get("input_tokens", 0)
            + latest_usage.get("cache_read_input_tokens", 0)
            + latest_usage.get("cache_creation_input_tokens", 0)
        )

        percentage = total_tokens / MAX_CONTEXT_TOKENS
        return total_tokens, percentage

    except Exception:
        return None, None


def handle_pre_compact(data: dict) -> None:
    """Handle PreCompact event - this is the reliable signal.

    PreCompact fires at ~78% context usage, which means we should
    prompt for handoff notes before compaction happens.
    """
    trigger = data.get("trigger", "unknown")

    # Only act on auto-compact (user-triggered /compact is intentional)
    if trigger == "auto":
        # Try to get exact usage from payload (v2.1.6+)
        tokens, pct = get_context_from_payload(data)
        if pct is not None:
            usage_info = f"Context at {int(pct * 100)}% ({tokens:,} tokens). "
        else:
            usage_info = "Context is filling up (auto-compact triggered at ~78%). "

        print(
            json.dumps(
                {
                    "decision": "block",
                    "reason": (
                        f"{usage_info}"
                        "Before compaction, please update handoff.md with: "
                        "current progress, decisions made, and next steps."
                    ),
                }
            )
        )
    else:
        # Manual compact - allow it
        print(json.dumps({}))


def handle_stop(data: dict) -> None:
    """Handle Stop event - checks context usage and warns if high."""
    # Prevent infinite loops
    if data.get("stop_hook_active", False):
        print(json.dumps({}))
        return

    # Try payload first (v2.1.6+), fall back to transcript parsing
    tokens, pct = get_context_from_payload(data)
    if pct is None:
        transcript_path = data.get("transcript_path", "")
        if not transcript_path:
            print(json.dumps({}))
            return
        tokens, pct = get_context_from_transcript(transcript_path)

    # Only trigger if we have valid data and it's above threshold
    if pct is not None and pct >= STOP_HOOK_THRESHOLD:
        print(
            json.dumps(
                {
                    "decision": "block",
                    "reason": (
                        f"Context usage at {int(pct * 100)}% ({tokens:,} tokens). "
                        "Consider creating handoff notes in handoff.md before continuing."
                    ),
                }
            )
        )
    else:
        print(json.dumps({}))


def handle_post_tool_use(data: dict) -> None:
    """Handle PostToolUse - just pass through."""
    print(json.dumps({}))


def main():
    """Route to appropriate handler based on hook event."""
    try:
        data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        print(json.dumps({}))
        return

    event_name = data.get("hook_event_name", "")

    if event_name == "PreCompact":
        handle_pre_compact(data)
    elif event_name == "Stop":
        handle_stop(data)
    elif event_name == "PostToolUse":
        handle_post_tool_use(data)
    else:
        # Unknown event, allow
        print(json.dumps({}))


if __name__ == "__main__":
    main()
