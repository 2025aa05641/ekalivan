"""OllamaProvider tests against a mocked HTTP transport."""

import json

import httpx
import pytest
from pydantic import BaseModel

from app.infrastructure.llm_provider import OllamaProvider


class _EchoResponse(BaseModel):
    """Minimal schema used to exercise provider request/response handling."""

    value: str


async def test_complete_returns_validated_response() -> None:
    """A well-formed Ollama response is parsed and validated against the schema."""

    def handler(request: httpx.Request) -> httpx.Response:
        body = json.loads(request.content)
        assert body["model"] == "llama3.1"
        assert body["stream"] is False
        assert body["format"] == _EchoResponse.model_json_schema()
        return httpx.Response(200, json={"response": json.dumps({"value": "hello"})})

    client = httpx.AsyncClient(transport=httpx.MockTransport(handler))
    provider = OllamaProvider(base_url="http://localhost:11434", model="llama3.1", client=client)

    result = await provider.complete("prompt text", _EchoResponse)

    assert result == _EchoResponse(value="hello")
    await client.aclose()


async def test_complete_raises_value_error_on_invalid_json() -> None:
    """A response that doesn't validate against the schema fails the node explicitly."""

    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json={"response": "not valid json"})

    client = httpx.AsyncClient(transport=httpx.MockTransport(handler))
    provider = OllamaProvider(base_url="http://localhost:11434", model="llama3.1", client=client)

    with pytest.raises(ValueError, match="failed schema validation"):
        await provider.complete("prompt text", _EchoResponse)
    await client.aclose()


async def test_complete_raises_for_http_error_status() -> None:
    """An HTTP error status from the Ollama server propagates as an exception."""

    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(500, text="internal error")

    client = httpx.AsyncClient(transport=httpx.MockTransport(handler))
    provider = OllamaProvider(base_url="http://localhost:11434", model="llama3.1", client=client)

    with pytest.raises(httpx.HTTPStatusError):
        await provider.complete("prompt text", _EchoResponse)
    await client.aclose()
