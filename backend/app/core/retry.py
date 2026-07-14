"""Bounded retry with exponential backoff for transient tool failures."""

import asyncio
import logging
from collections.abc import Awaitable, Callable
from typing import TypeVar

logger = logging.getLogger(__name__)

_T = TypeVar("_T")


async def retry_with_backoff(  # noqa: UP047 -- runtime is Python 3.11; PEP 695 syntax is a SyntaxError there.
    operation: Callable[[], Awaitable[_T]],
    *,
    max_attempts: int = 3,
    initial_delay_seconds: float = 1.0,
    backoff_multiplier: float = 2.0,
) -> _T:
    """Run ``operation``, retrying with exponential backoff if it raises.

    Args:
        operation: Zero-argument async callable to attempt.
        max_attempts: Total attempts made before the last exception propagates.
        initial_delay_seconds: Delay before the first retry.
        backoff_multiplier: Growth factor applied to the delay after each retry.

    Returns:
        The result of whichever attempt first succeeds.

    Raises:
        AssertionError: Unreachable; the loop always returns or re-raises.
    """
    delay = initial_delay_seconds
    for attempt in range(1, max_attempts + 1):
        try:
            return await operation()
        except Exception:
            if attempt == max_attempts:
                raise
            logger.warning(
                "Transient failure on attempt %d/%d, retrying in %.1fs.", attempt, max_attempts, delay, exc_info=True
            )
            await asyncio.sleep(delay)
            delay *= backoff_multiplier
    raise AssertionError("unreachable: loop always returns or raises")
