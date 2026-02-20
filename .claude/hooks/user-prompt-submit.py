#!/usr/bin/env python3
"""User prompt submit validation hook.

Triggered when the user submits a prompt before processing.
Can be used for:
- Input validation
- Prompt logging for analytics
- Security checks
- Custom pre-processing

Returns empty {} to allow the prompt, or {blocked: true, message: "reason"}
to block the prompt with an explanation.
"""

import json
import sys
from datetime import datetime
from pathlib import Path

LOG_DIR = Path(".claudify") / "logs"

# Security patterns to warn about (not block)
SENSITIVE_PATTERNS = [
    "password",
    "secret",
    "api_key",
    "api-key",
    "apikey",
    "token",
    "credential",
]


def get_log_file():
    """Get the prompt log file for today."""
    today = datetime.now().strftime("%Y-%m-%d")
    return LOG_DIR / f"prompts-{today}.log"


def log_prompt(prompt: str, metadata: dict):
    """Log user prompt to daily log file (without sensitive content)."""
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    log_file = get_log_file()

    timestamp = datetime.now().isoformat()
    prompt_length = len(prompt)

    # Log metadata only, not actual prompt content (privacy)
    entry = f"[{timestamp}] PROMPT_SUBMIT: length={prompt_length}\n"

    with open(log_file, "a", encoding="utf-8") as f:
        f.write(entry)


def check_sensitive_content(prompt: str) -> list:
    """Check for potentially sensitive content in prompt."""
    warnings = []
    prompt_lower = prompt.lower()

    for pattern in SENSITIVE_PATTERNS:
        if pattern in prompt_lower:
            warnings.append(pattern)

    return warnings


def main():
    """Handle user prompt submit event."""
    try:
        data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        print(json.dumps({}))
        return

    prompt = data.get("prompt", "")
    metadata = data.get("metadata", {})

    # Log the prompt submission
    log_prompt(prompt, metadata)

    # Check for sensitive content (warn but don't block)
    warnings = check_sensitive_content(prompt)
    if warnings:
        # Print warning to stderr (visible to user)
        print(
            f"[prompt-submit] Note: Prompt may contain sensitive terms: {', '.join(warnings)}",
            file=sys.stderr,
        )

    # Return empty response to allow the prompt
    # To block: return {"blocked": True, "message": "Reason for blocking"}
    print(json.dumps({}))


if __name__ == "__main__":
    main()
