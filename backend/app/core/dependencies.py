"""FastAPI dependency providers."""

from collections.abc import AsyncIterator

from fastapi import Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.database import session_scope


async def get_db_session(request: Request) -> AsyncIterator[AsyncSession]:
    """Resolve an async database session for one request.

    Args:
        request: Current FastAPI request.

    Yields:
        Request-scoped async SQLAlchemy session.
    """
    async for session in session_scope(request.app.state.session_factory):
        yield session
