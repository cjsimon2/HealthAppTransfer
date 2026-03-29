"""
context-monitor.py - Monitors context window usage.

Tracks estimated token usage and warns when the context window
is approaching capacity.
"""

import logging
import os
import sys

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

MAX_CONTEXT_TOKENS = int(os.environ.get("MAX_CONTEXT_TOKENS", "200000"))
WARNING_THRESHOLD = float(os.environ.get("CONTEXT_WARNING_THRESHOLD", "0.8"))


def estimate_tokens(text):
    return len(text) // 4


def main():
    context_content = os.environ.get("HOOK_CONTEXT", "")
    estimated_tokens = estimate_tokens(context_content)
    usage_ratio = estimated_tokens / MAX_CONTEXT_TOKENS if MAX_CONTEXT_TOKENS > 0 else 0

    logger.info(
        "Context usage: ~%d tokens / %d max (%.1f%%)",
        estimated_tokens,
        MAX_CONTEXT_TOKENS,
        usage_ratio * 100,
    )

    if usage_ratio >= 0.95:
        logger.critical("Context window nearly full (%.1f%%). Immediate action needed.", usage_ratio * 100)
        return 2
    elif usage_ratio >= WARNING_THRESHOLD:
        logger.warning("Context window usage high (%.1f%%). Consider summarizing.", usage_ratio * 100)
        return 1

    logger.info("Context usage within safe limits.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
