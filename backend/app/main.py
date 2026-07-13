"""FastAPI application entry point."""

import asyncio
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from app.core.config import get_settings
from app.core.errors import register_exception_handlers
from app.core.interfaces import ILlmProvider, IMcpTool
from app.core.logging import configure_logging
from app.features.video_generator.graph import build_video_generation_graph
from app.features.video_generator.mcp_tools import MarkItDownTool
from app.features.video_generator.router import router as video_generator_router
from app.infrastructure.database import create_engine, create_session_factory
from app.infrastructure.llm_provider import OllamaProvider


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """Initialize and release application-owned async resources."""
    settings = get_settings()
    configure_logging(settings.log_level)
    try:
        yield
    finally:
        background_tasks: set[asyncio.Task[None]] = app.state.background_tasks
        for task in background_tasks:
            task.cancel()
        if background_tasks:
            await asyncio.gather(*background_tasks, return_exceptions=True)
        if app.state.owns_engine:
            await app.state.engine.dispose()
        if app.state.llm_http_client is not None:
            await app.state.llm_http_client.aclose()


def create_app(
    *,
    engine: AsyncEngine | None = None,
    session_factory: async_sessionmaker[AsyncSession] | None = None,
    parser_tool: IMcpTool | None = None,
    llm_provider: ILlmProvider | None = None,
) -> FastAPI:
    """Build the configured API application for production or test use.

    Args:
        engine: Async engine to use in place of one built from settings.
        session_factory: Session factory to use in place of one built from ``engine``.
        parser_tool: Intake-stage MCP tool to use in place of ``MarkItDownTool``.
        llm_provider: LLM provider to use in place of one built from settings (``OllamaProvider``).

    Returns:
        Fully configured FastAPI application.
    """
    settings = get_settings()
    app = FastAPI(title=settings.app_name, debug=settings.app_debug, lifespan=lifespan)
    app.state.engine = engine or create_engine(settings.database_url)
    app.state.owns_engine = engine is None
    app.state.session_factory = session_factory or create_session_factory(app.state.engine)
    app.state.llm_http_client = None
    if llm_provider is None:
        app.state.llm_http_client = httpx.AsyncClient(timeout=settings.ollama_timeout_seconds)
        llm_provider = OllamaProvider(
            base_url=settings.ollama_base_url, model=settings.ollama_model, client=app.state.llm_http_client
        )
    app.state.video_generation_graph = build_video_generation_graph(parser_tool or MarkItDownTool(), llm_provider)
    app.state.background_tasks = set()
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=False,
        allow_methods=["GET", "POST"],
        allow_headers=["Content-Type"],
    )
    register_exception_handlers(app)
    app.include_router(video_generator_router)

    @app.get("/health", tags=["system"])
    async def health() -> JSONResponse:
        """Return a lightweight liveness response without external dependencies."""
        return JSONResponse({"status": "ok", "environment": settings.app_environment})

    return app


app = create_app()
