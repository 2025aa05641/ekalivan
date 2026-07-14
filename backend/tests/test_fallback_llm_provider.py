"""Unit tests for the fallback LLM provider."""

import pytest
from pydantic import BaseModel

from app.core.interfaces import ILlmProvider, ResponseModel
from app.infrastructure.fallback_llm_provider import FallbackLlmProvider


class _Echo(BaseModel):
    """Minimal schema used to exercise ``complete`` without pipeline models."""

    text: str


class _StubProvider(ILlmProvider):
    """Deterministic provider stand-in that either raises or returns a canned value."""

    def __init__(self, *, fails: bool = False, value: str = "ok") -> None:
        self.fails = fails
        self.value = value
        self.calls = 0

    async def complete(self, prompt: str, response_schema: type[ResponseModel]) -> ResponseModel:
        self.calls += 1
        if self.fails:
            raise ConnectionError("provider unavailable")
        return response_schema.model_validate({"text": self.value})


async def test_fallback_returns_the_primary_providers_result_without_calling_others() -> None:
    """A healthy primary provider is used, and the fallback is never invoked."""
    primary = _StubProvider(value="primary")
    fallback = _StubProvider(value="fallback")
    provider = FallbackLlmProvider([primary, fallback])

    result = await provider.complete("prompt", _Echo)

    assert result == _Echo(text="primary")
    assert primary.calls == 1
    assert fallback.calls == 0


async def test_fallback_uses_the_next_provider_when_the_primary_fails() -> None:
    """A failing primary provider falls through to the next configured provider."""
    primary = _StubProvider(fails=True)
    fallback = _StubProvider(value="fallback")
    provider = FallbackLlmProvider([primary, fallback])

    result = await provider.complete("prompt", _Echo)

    assert result == _Echo(text="fallback")
    assert primary.calls == 1
    assert fallback.calls == 1


async def test_fallback_raises_the_last_error_once_every_provider_fails() -> None:
    """The final provider's exception propagates once the whole chain is exhausted."""
    provider = FallbackLlmProvider([_StubProvider(fails=True), _StubProvider(fails=True)])

    with pytest.raises(ConnectionError, match="provider unavailable"):
        await provider.complete("prompt", _Echo)


def test_fallback_requires_at_least_one_provider() -> None:
    """An empty provider list is a configuration error, not a runtime surprise."""
    with pytest.raises(ValueError, match="at least one provider"):
        FallbackLlmProvider([])
