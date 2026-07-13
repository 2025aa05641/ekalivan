"""Async database fixtures for backend integration tests."""

import asyncio
from collections.abc import AsyncIterator

import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker, create_async_engine

from app.core.interfaces import ILlmProvider, IMcpTool, ResponseModel
from app.infrastructure.database import Base
from app.main import create_app

FAILURE_SENTINEL_PATH = "trigger-parser-error.pdf"


class FakeParserTool(IMcpTool):
    """Fast, deterministic Intake-stage stand-in for API-level tests."""

    async def execute(self, **kwargs: object) -> object:
        """Return deterministic Markdown, or raise for the failure sentinel path.

        Raises:
            RuntimeError: If ``file_path`` equals ``FAILURE_SENTINEL_PATH``.
        """
        file_path = kwargs["file_path"]
        if file_path == FAILURE_SENTINEL_PATH:
            raise RuntimeError("Simulated parser failure.")
        return f"# Mock Markdown\n\nParsed content for {file_path}."


class FakeLlmProvider(ILlmProvider):
    """Deterministic Curriculum-shaped LLM stand-in shared across skill, agent, and API tests."""

    def __init__(self) -> None:
        self.last_prompt: str | None = None

    async def complete(self, prompt: str, response_schema: type[ResponseModel]) -> ResponseModel:
        """Record the assembled prompt and return a schema-valid single-section response.

        Returns:
            A ``response_schema`` instance with one mock section.
        """
        self.last_prompt = prompt
        return response_schema.model_validate({"sections": [{"title": "Mock Section", "content": "Mock content."}]})


@pytest_asyncio.fixture
async def session_factory() -> AsyncIterator[async_sessionmaker[AsyncSession]]:
    """Create an isolated async SQLite database for one test.

    Yields:
        Async session factory bound to the isolated database.
    """
    engine: AsyncEngine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    try:
        yield async_sessionmaker(engine, expire_on_commit=False)
    finally:
        await engine.dispose()


@pytest_asyncio.fixture
async def client(session_factory: async_sessionmaker[AsyncSession]) -> AsyncIterator[AsyncClient]:
    """Create an API client connected to the test database.

    Yields:
        HTTP client configured with the isolated application instance.
    """
    app = create_app(session_factory=session_factory, parser_tool=FakeParserTool(), llm_provider=FakeLlmProvider())
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as test_client:
        yield test_client
    background_tasks: set[asyncio.Task[None]] = app.state.background_tasks
    for task in background_tasks:
        task.cancel()
    if background_tasks:
        await asyncio.gather(*background_tasks, return_exceptions=True)
