"""FastAPI application entry point."""

import asyncio
import mimetypes
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from pathlib import Path

import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from app.core.config import get_settings
from app.core.errors import register_exception_handlers
from app.core.interfaces import ILlmProvider, IMcpTool
from app.core.logging import configure_logging
from app.features.video_generator.graph import build_video_generation_graph
from app.features.video_generator.mcp_tools import EdgeTtsTool, FFmpegTool, MarkItDownTool, MoviePyTool
from app.features.video_generator.router import router as video_generator_router
from app.infrastructure.database import create_engine, create_session_factory
from app.infrastructure.llm_provider import OllamaProvider
from app.infrastructure.storage import StorageTool

# Windows' registry-backed mimetypes database maps ".mp4" to the non-standard
# "video/mpeg4", which Chrome's <video> element refuses to play inline.
mimetypes.add_type("video/mp4", ".mp4")


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
    tts_tool: IMcpTool | None = None,
    composition_tool: IMcpTool | None = None,
    encode_tool: IMcpTool | None = None,
    storage_tool: IMcpTool | None = None,
) -> FastAPI:
    """Build the configured API application for production or test use.

    Args:
        engine: Async engine to use in place of one built from settings.
        session_factory: Session factory to use in place of one built from ``engine``.
        parser_tool: Intake-stage MCP tool to use in place of ``MarkItDownTool``.
        llm_provider: LLM provider to use in place of one built from settings (``OllamaProvider``).
        tts_tool: Narration-stage MCP tool to use in place of ``EdgeTtsTool``.
        composition_tool: Assembly-stage composition MCP tool to use in place of ``MoviePyTool``.
        encode_tool: Assembly-stage encode MCP tool to use in place of ``FFmpegTool``.
        storage_tool: Publishing-stage MCP tool to use in place of ``StorageTool``.

    Returns:
        Fully configured FastAPI application.
    """
    settings = get_settings()
    static_assets_dir = Path(settings.static_assets_path)
    static_assets_dir.mkdir(parents=True, exist_ok=True)
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
    app.state.video_generation_graph = build_video_generation_graph(
        parser_tool or MarkItDownTool(),
        llm_provider,
        tts_tool or EdgeTtsTool(),
        static_assets_dir / "audio",
        composition_tool or MoviePyTool(),
        encode_tool or FFmpegTool(),
        static_assets_dir / "video",
        storage_tool or StorageTool(),
        static_assets_dir,
    )
    app.state.background_tasks = set()
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=False,
        allow_methods=["GET", "POST"],
        allow_headers=["Content-Type", "Cache-Control", "Range"],
        expose_headers=["Content-Range", "Accept-Ranges", "Content-Length"],
        max_age=3600,
    )
    register_exception_handlers(app)
    app.include_router(video_generator_router)
    app.mount("/static", StaticFiles(directory=static_assets_dir), name="static")

    @app.get("/health", tags=["system"])
    async def health() -> JSONResponse:
        """Return a lightweight liveness response without external dependencies."""
        return JSONResponse({"status": "ok", "environment": settings.app_environment})

    return app


app = create_app()
