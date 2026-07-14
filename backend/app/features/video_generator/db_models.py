"""SQLAlchemy persistence models for video generation."""

from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import JSON, DateTime, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import Uuid

from app.infrastructure.database import Base


class VideoJob(Base):
    """Persisted asynchronous video-generation job."""

    __tablename__ = "video_jobs"

    id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid4)
    class_level: Mapped[str] = mapped_column(String(32), nullable=False)
    subject: Mapped[str] = mapped_column(String(128), nullable=False)
    chapter_title: Mapped[str] = mapped_column(String(256), nullable=False)
    file_storage_path: Mapped[str] = mapped_column(String(512), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="QUEUED")
    markdown_content: Mapped[str | None] = mapped_column(Text(), nullable=True)
    sections: Mapped[list[dict[str, str]] | None] = mapped_column(JSON(), nullable=True)
    storyboard_beats: Mapped[list[dict[str, object]] | None] = mapped_column(JSON(), nullable=True)
    narrated_beats: Mapped[list[dict[str, object]] | None] = mapped_column(JSON(), nullable=True)
    error_message: Mapped[str | None] = mapped_column(Text(), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )
