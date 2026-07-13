"""Async SQLAlchemy database configuration and session lifecycle."""

from collections.abc import AsyncIterator

from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Declarative base for application-owned relational models."""


def create_engine(database_url: str) -> AsyncEngine:
    """Create the application's async SQLAlchemy engine.

    Args:
        database_url: SQLAlchemy async database URL.

    Returns:
        Configured async engine. It does not open a connection eagerly.
    """
    return create_async_engine(database_url, pool_pre_ping=True)


def create_session_factory(engine: AsyncEngine) -> async_sessionmaker[AsyncSession]:
    """Create a non-expiring async session factory for request dependencies.

    Args:
        engine: Async engine bound to the configured database.

    Returns:
        Session factory bound to ``engine``.
    """
    return async_sessionmaker(engine, expire_on_commit=False)


async def session_scope(session_factory: async_sessionmaker[AsyncSession]) -> AsyncIterator[AsyncSession]:
    """Yield one async transaction session and close it after the request.

    Args:
        session_factory: Factory used to construct the session.

    Yields:
        Open async SQLAlchemy session.
    """
    session = session_factory()
    try:
        yield session
    finally:
        await session.close()
