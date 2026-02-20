#!/usr/bin/env python3
"""Post-tool hook to update STATE.md on git commit/push.

This hook only triggers on git commit and git push commands,
updating the timestamp and tracking completed tasks from commits.
"""

import json
import re
import sys
from datetime import datetime
from pathlib import Path

STATE_FILE = Path("STATE.md")


def get_current_date():
    """Get current date in readable format."""
    return datetime.now().strftime("%Y-%m-%d %H:%M")


def read_state_file():
    """Read the current STATE.md content."""
    if STATE_FILE.exists():
        return STATE_FILE.read_text(encoding="utf-8")
    return None


def update_last_updated(content: str) -> str:
    """Update the Last Updated timestamp."""
    date_pattern = r"\*\*Last Updated:\*\* .+"
    new_date = f"**Last Updated:** {get_current_date()}"
    if re.search(date_pattern, content):
        return re.sub(date_pattern, new_date, content)
    return content


def extract_commit_message(command: str, result: str) -> str | None:
    """Extract commit message from a git commit command.

    Tries to parse from command flags (-m) or from the result output.
    Returns the commit message or None if not found.
    """
    # Try to extract from -m flag in command
    # Handles: git commit -m "message", git commit -m 'message', git commit -m "$(cat <<'EOF'...)"
    m_flag_patterns = [
        r'-m\s+"([^"$]+)"',  # -m "message" (no $ to avoid heredoc)
        r"-m\s+'([^']+)'",  # -m 'message'
    ]
    for pattern in m_flag_patterns:
        match = re.search(pattern, command, re.DOTALL)
        if match:
            msg = match.group(1).strip()
            # Take first line only for table display
            first_line = msg.split("\n")[0].strip()
            if first_line:
                return first_line

    # Try to extract from result (git outputs commit message)
    # Look for patterns like: [main abc1234] Commit message here
    result_match = re.search(r"\[[\w/-]+\s+[\da-f]+\]\s+(.+)", result)
    if result_match:
        return result_match.group(1).strip()

    return None


def add_to_completed_tasks(content: str, task: str, files_changed: str = "See commit") -> str:
    """Add a completed task to the Completed Tasks table.

    Uses section-based parsing to safely insert without corruption.
    """
    # Skip if this exact task is already in the table
    if task in content:
        return content

    # Find the Completed Tasks section
    section_marker = "## Completed Tasks"
    section_start = content.find(section_marker)
    if section_start == -1:
        return content

    # Find where the section ends - look for the next ## section
    after_section = content[section_start:]
    next_section = after_section.find("\n## ", 1)  # Start from 1 to skip current ##
    if next_section == -1:
        next_section = len(after_section)

    # Extract just this section's content
    section_content = after_section[:next_section]

    # Find the table separator line (|------|...)
    lines = section_content.split("\n")
    separator_idx = -1
    for i, line in enumerate(lines):
        if line.startswith("|--"):
            separator_idx = i
            break

    if separator_idx == -1:
        return content  # No table found

    # Insert new row right after the separator (at top of completed tasks)
    date_str = datetime.now().strftime("%Y-%m-%d")
    new_row = f"| ✅ {task} | {date_str} | {files_changed} |"
    lines.insert(separator_idx + 1, new_row)

    # Reconstruct content
    new_section = "\n".join(lines)
    new_content = content[:section_start] + new_section + after_section[next_section:]

    return new_content


def extract_result_string(tool_response) -> str:
    """Extract a string representation from tool_response.

    The protocol provides tool_response as an object, but we need
    a string for pattern matching (test results, git output, etc.).
    """
    if isinstance(tool_response, str):
        return tool_response
    if isinstance(tool_response, dict):
        # Try common fields that contain output text
        for field in ("stdout", "output", "content", "result", "message"):
            if field in tool_response:
                val = tool_response[field]
                if isinstance(val, str):
                    return val
        # Fallback: stringify the whole response
        return json.dumps(tool_response)
    return str(tool_response)


def is_git_commit_or_push(command: str) -> bool:
    """Check if command is a git commit or push operation."""
    cmd = command.strip()
    return "git commit" in cmd or "git push" in cmd


def main():
    """Process hook input and update STATE.md only on git commit/push."""
    try:
        data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        print(json.dumps({}))
        return

    tool_name = data.get("tool_name", "")
    tool_input = data.get("tool_input", {})
    command = tool_input.get("command", "")

    # Only process git commit or git push commands
    if tool_name != "Bash" or not is_git_commit_or_push(command):
        print(json.dumps({}))
        return

    # Protocol uses tool_response (object), extract string for pattern matching
    tool_response = data.get("tool_response", {})
    result = extract_result_string(tool_response)

    # Read current state
    content = read_state_file()
    if not content:
        print(json.dumps({}))
        return

    # Update last updated timestamp
    content = update_last_updated(content)

    # Track git commits to Completed Tasks
    if "git commit" in command and "error" not in result.lower():
        commit_msg = extract_commit_message(command, result)
        if commit_msg:
            content = add_to_completed_tasks(content, commit_msg)

    # Write updated state
    try:
        STATE_FILE.write_text(content, encoding="utf-8")
    except (PermissionError, OSError) as e:
        print(f"[state-tracker] Cannot write STATE.md: {e}", file=sys.stderr)

    print(json.dumps({}))


if __name__ == "__main__":
    main()
