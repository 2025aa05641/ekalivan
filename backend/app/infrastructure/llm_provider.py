"""Ollama-backed implementation of the LLM provider port."""

import httpx
from pydantic import ValidationError

from app.core.interfaces import ILlmProvider, ResponseModel


class OllamaProvider(ILlmProvider):
    """Calls a local Ollama server for structured, schema-validated completions."""

    def __init__(self, base_url: str, model: str, client: httpx.AsyncClient) -> None:
        """Create the provider with its target server, model, and HTTP client.

        Args:
            base_url: Base URL of the Ollama server, e.g. ``http://localhost:11434``.
            model: Name of the pulled Ollama model to complete against.
            client: Async HTTP client used for requests; its lifecycle is owned by the caller.
        """
        self._base_url = base_url.rstrip("/")
        self._model = model
        self._client = client

    async def complete(self, prompt: str, response_schema: type[ResponseModel]) -> ResponseModel:
        """Complete a prompt and validate the response against ``response_schema``.

        Args:
            prompt: Fully assembled prompt text.
            response_schema: Pydantic model the response must validate as.

        Returns:
            The response parsed and validated as ``response_schema``.

        Raises:
            ValueError: If the model's output does not validate against ``response_schema``.
        """
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
