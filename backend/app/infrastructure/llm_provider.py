"""Ollama-backed implementation of the LLM provider port."""

import httpx
from pydantic import ValidationError

from app.core.interfaces import ILlmProvider, ResponseModel
from app.core.retry import retry_with_backoff


class OllamaProvider(ILlmProvider):
    """Calls a local Ollama server for structured, schema-validated completions."""

    def __init__(
        self,
        base_url: str,
        model: str,
        client: httpx.AsyncClient,
        *,
        max_attempts: int = 2,
        initial_retry_delay_seconds: float = 2.0,
    ) -> None:
        """Create the provider with its target server, model, and HTTP client.

        Args:
            base_url: Base URL of the Ollama server, e.g. ``http://localhost:11434``.
            model: Name of the pulled Ollama model to complete against.
            client: Async HTTP client used for requests; its lifecycle is owned by the caller.
            max_attempts: Total completion attempts before a transient failure propagates.
            initial_retry_delay_seconds: Delay before the first retry.
        """
        self._base_url = base_url.rstrip("/")
        self._model = model
        self._client = client
        self._max_attempts = max_attempts
        self._initial_retry_delay_seconds = initial_retry_delay_seconds

    async def complete(self, prompt: str, response_schema: type[ResponseModel]) -> ResponseModel:
        """Complete a prompt and validate the response against ``response_schema``.

        Retries the completion with exponential backoff on transient failures
        (connection drops, timeouts, non-2xx responses).

        Args:
            prompt: Fully assembled prompt text.
            response_schema: Pydantic model the response must validate as.

        Returns:
            The response parsed and validated as ``response_schema``.
        """

        async def _complete_once() -> ResponseModel:
            http_response = await self._client.post(
                f"{self._base_url}/api/generate",
                json={
                    "model": self._model,
                    "prompt": prompt,
                    "stream": False,
                    "format": response_schema.model_json_schema(),
                },
            )
            http_response.raise_for_status()
            raw_text = http_response.json()["response"]
            try:
                return response_schema.model_validate_json(raw_text)
            except ValidationError as exc:
                raise ValueError(
                    f"Ollama response for '{response_schema.__name__}' failed schema validation: {exc}"
                ) from exc

        return await retry_with_backoff(
            _complete_once,
            max_attempts=self._max_attempts,
            initial_delay_seconds=self._initial_retry_delay_seconds,
        )
