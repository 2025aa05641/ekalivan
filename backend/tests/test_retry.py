"""Unit tests for the bounded retry-with-backoff helper."""

import pytest

from app.core.retry import retry_with_backoff


async def test_retry_with_backoff_returns_first_success_without_retrying() -> None:
    """A successful first attempt is returned without any retry delay."""
    attempts = 0

    async def _operation() -> str:
        nonlocal attempts
        attempts += 1
        return "ok"

    result = await retry_with_backoff(_operation, max_attempts=3, initial_delay_seconds=0.01)

    assert result == "ok"
    assert attempts == 1


async def test_retry_with_backoff_recovers_after_transient_failures() -> None:
    """A failure that clears within the attempt budget still yields a result."""
    attempts = 0

    async def _operation() -> str:
        nonlocal attempts
        attempts += 1
        if attempts < 3:
            raise ConnectionError("transient")
        return "ok"

    result = await retry_with_backoff(_operation, max_attempts=3, initial_delay_seconds=0.01)

    assert result == "ok"
    assert attempts == 3


async def test_retry_with_backoff_raises_the_final_exception_once_exhausted() -> None:
    """The last attempt's exception propagates once the attempt budget is spent."""
    attempts = 0

    async def _operation() -> str:
        nonlocal attempts
        attempts += 1
        raise RuntimeError(f"failure {attempts}")

    with pytest.raises(RuntimeError, match="failure 2"):
        await retry_with_backoff(_operation, max_attempts=2, initial_delay_seconds=0.01)

    assert attempts == 2
