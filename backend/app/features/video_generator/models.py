"""Validated API contracts and shared pipeline state models."""

from enum import StrEnum
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, Field, StringConstraints

NonBlankString = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1)]


class VideoTaskStatus(StrEnum):
    """Lifecycle states exposed by the asynchronous generation API."""

    QUEUED = "QUEUED"
    PROCESSING = "PROCESSING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"


class VideoGenerationRequest(BaseModel):
    """Input accepted to create a deterministic video-generation task."""

    class_level: NonBlankString
    subject: NonBlankString
    chapter_title: NonBlankString
    file_storage_path: NonBlankString


class VideoGenerationResponse(BaseModel):
    """Asynchronous acceptance response for a newly created video job."""

    task_id: UUID
    status: VideoTaskStatus


class ChapterSection(BaseModel):
    """Structured chapter section produced by the curriculum stage."""

    title: NonBlankString
    content: NonBlankString


class ScriptBeat(BaseModel):
    """Timed storyboard beat produced by the storyboarding stage."""

    narration: NonBlankString
    visual_prompt: NonBlankString
    duration_seconds: float = Field(gt=0)


class JobStatusResponse(BaseModel):
    """Current status response for a persisted video-generation job."""

    task_id: UUID
    status: VideoTaskStatus
    markdown_content: str | None = None
    sections: list[ChapterSection] | None = None
    storyboard_beats: list[ScriptBeat] | None = None
    error_message: str | None = None


class VideoGenerationState(BaseModel):
    """Shared immutable-by-convention state that moves through LangGraph nodes."""

    file_path: str
    markdown_content: str | None = None
    sections: list[ChapterSection] = Field(default_factory=list)
    storyboard_beats: list[ScriptBeat] = Field(default_factory=list)
    output_video_path: str | None = None
    error_message: str | None = None
