"""Ports that protect application layers from provider and tool details."""

from abc import ABC, abstractmethod
from typing import TypeVar

from pydantic import BaseModel

ResponseModel = TypeVar("ResponseModel", bound=BaseModel)


class ILlmProvider(ABC):
    """Port used by skills to obtain validated structured LLM responses."""

    @abstractmethod
    async def complete(self, prompt: str, response_schema: type[ResponseModel]) -> ResponseModel:
        """Complete a prompt and validate it as the requested schema."""


class IMcpTool(ABC):
    """Async adapter contract for external document, media, and storage tools."""

    @abstractmethod
    async def execute(self, **kwargs: object) -> object:
        """Execute a tool operation through its normalized async boundary."""
