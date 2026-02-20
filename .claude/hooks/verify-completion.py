#!/usr/bin/env python3
"""Stop hook to remind about verification when completion is claimed.

This hook reads the transcript to find the last assistant message,
checks for completion claims, and blocks stopping to request
verification evidence if needed.
"""

import json
import re
import sys
from pathlib import Path

# Phrases that indicate completion claims
COMPLETION_PHRASES = [
    r"\btask complete\b",
    r"\bimplementation complete\b",
    r"\bsubtask complete\b",
    r"\bready for review\b",
    r"\bready for qa\b",
    r"\ball done\b",
    r"\bfinished implementing\b",
]

# Evidence that verification was done
VERIFICATION_INDICATORS = [
    "## completion verification",
    "### verification",
    "- [x] build",
    "- [x] tests pass",
    "acceptance criteria",
    "files changed:",
    "test status:",
    "tests pass",
]


class TranscriptReadError(Exception):
    """Error reading transcript file."""

    pass


class TranscriptParseError(Exception):
    """Error parsing JSON in transcript file."""

    pass


def get_last_assistant_message(transcript_path: str) -> str:
    """Read transcript and extract the last assistant message.

    The transcript is a JSONL file with conversation entries.

    Raises:
        TranscriptReadError: If the file cannot be read (IO error)
        TranscriptParseError: If all lines fail JSON parsing
    """
    path = Path(transcript_path)
    if not path.exists():
        return ""

    try:
        with open(path, encoding="utf-8") as f:
            lines = f.readlines()
    except OSError as e:
        raise TranscriptReadError(f"Failed to read transcript: {e}") from e

    last_message = ""
    parse_errors = 0
    total_lines = 0

    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue
        total_lines += 1
        try:
            entry = json.loads(stripped)
            # Look for assistant messages
            if entry.get("role") == "assistant":
                content = entry.get("content", "")
                if isinstance(content, str):
                    last_message = content
                elif isinstance(content, list):
                    # Content might be a list of blocks
                    text_parts = []
                    for block in content:
                        if isinstance(block, dict) and block.get("type") == "text":
                            text_parts.append(block.get("text", ""))
                    last_message = "\n".join(text_parts)
        except json.JSONDecodeError:
            parse_errors += 1
            continue

    # If ALL lines failed to parse, that's a significant error
    if total_lines > 0 and parse_errors == total_lines:
        raise TranscriptParseError(f"All {total_lines} transcript lines failed JSON parsing")

    return last_message


def contains_completion_claim(text: str) -> bool:
    """Check if text contains a strong completion claim."""
    text_lower = text.lower()
    return any(re.search(pattern, text_lower) for pattern in COMPLETION_PHRASES)


def has_verification_evidence(text: str) -> bool:
    """Check if the message contains verification evidence."""
    text_lower = text.lower()
    return any(indicator in text_lower for indicator in VERIFICATION_INDICATORS)


def main():
    """Process Stop event and request verification if needed."""
    # Parse stdin JSON - differentiate parsing errors from other issues
    stdin_content = sys.stdin.read()
    try:
        data = json.loads(stdin_content)
    except json.JSONDecodeError as e:
        # Surface JSON parsing errors clearly
        print(
            json.dumps(
                {
                    "error": f"Invalid JSON input: {e}",
                    "input_preview": stdin_content[:200] if stdin_content else "(empty)",
                }
            )
        )
        return

    # Prevent infinite loops
    if data.get("stop_hook_active", False):
        print(json.dumps({}))
        return

    transcript_path = data.get("transcript_path", "")
    if not transcript_path:
        print(json.dumps({}))
        return

    # Get last message with explicit error handling
    try:
        last_message = get_last_assistant_message(transcript_path)
    except TranscriptReadError as e:
        # IO errors should be surfaced
        print(
            json.dumps({"error": f"Transcript read error: {e}", "transcript_path": transcript_path})
        )
        return
    except TranscriptParseError as e:
        # Parsing errors should be surfaced
        print(
            json.dumps(
                {"error": f"Transcript parse error: {e}", "transcript_path": transcript_path}
            )
        )
        return

    if not last_message:
        print(json.dumps({}))
        return

    # Only act on completion claims without verification
    if contains_completion_claim(last_message) and not has_verification_evidence(last_message):
        print(
            json.dumps(
                {
                    "decision": "block",
                    "reason": (
                        "Completion was claimed but verification evidence is missing. "
                        "Before stopping, please confirm: (1) Build/tests pass, "
                        "(2) Key files changed, (3) Acceptance criteria met."
                    ),
                }
            )
        )
    else:
        print(json.dumps({}))


if __name__ == "__main__":
    main()
