"""Composite LLM provider that falls back across multiple providers in order."""

import logging

from app.core.interfaces import ILlmProvider, ResponseModel

logger = logging.getLogger(__name__)


class FallbackLlmProvider(ILlmProvider):
    """Tries each configured provider in order, falling back on failure.

    Protects content generation from a single LLM outage or vendor lock-in
    (ADR-011): if the primary provider errors, the next configured provider
    is tried before the failure is surfaced to the caller.
    """

    def __init__(self, providers: list[ILlmProvider]) -> None:
        """Create the provider with an ordered, non-empty list of providers to try.

        Args:
            providers: Providers attempted in order; the first to succeed wins.

        Raises:
            ValueError: If ``providers`` is empty.
        """
        if not providers:
            raise ValueError("FallbackLlmProvider requires at least one provider.")
        self._providers = providers

    async def complete(self, prompt: str, response_schema: type[ResponseModel]) -> ResponseModel:
        """Complete ``prompt`` using the first provider that succeeds.

        Args:
            prompt: Fully assembled prompt text.
            response_schema: Pydantic model the response must validate as.

        Returns:
            The response parsed and validated as ``response_schema``.
        """
        last_error: Exception | None = None
        for index, provider in enumerate(self._providers):
            try:
                return await provider.complete(prompt, response_schema)
            except Exception as exc:
                last_error = exc
                logger.warning(
                    "LLM provider %d/%d failed, trying next.", index + 1, len(self._providers), exc_info=True
                )
        assert last_error is not None
        raise last_error
