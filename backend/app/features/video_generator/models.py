"""Validated API contracts and shared pipeline state models."""

try:
    from enum import StrEnum
except ImportError:
    from enum import Enum
    class StrEnum(str, Enum):
        pass

from datetime import datetime
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


class WordTimestamp(BaseModel):
    """Word-level timing captured from text-to-speech synthesis."""

    word: NonBlankString
    start_seconds: float = Field(ge=0)
    end_seconds: float = Field(gt=0)


class NarratedBeat(BaseModel):
    """Storyboard beat enriched with synthesized audio and word-level timing."""

    narration: NonBlankString
    visual_prompt: NonBlankString
    duration_seconds: float = Field(gt=0)
    audio_path: NonBlankString
    word_timestamps: list[WordTimestamp] = Field(default_factory=list)


class JobStatusResponse(BaseModel):
    """Current status response for a persisted video-generation job."""

    task_id: UUID
    status: VideoTaskStatus
    markdown_content: str | None = None
    sections: list[ChapterSection] | None = None
    storyboard_beats: list[ScriptBeat] | None = None
    narrated_beats: list[NarratedBeat] | None = None
    output_video_path: str | None = None
    video_url: str | None = None
    error_message: str | None = None


class JobMetrics(BaseModel):
    """Aggregate job counters exposed for operational observability."""

    total_jobs: int = Field(ge=0)
    counts_by_status: dict[str, int]
    average_completion_seconds: float | None = None


class RecentJobSummary(BaseModel):
    """Lightweight summary of a video-generation job for the dashboard list."""

    task_id: UUID
    status: VideoTaskStatus
    subject: str
    chapter_title: str
    class_level: str
    created_at: datetime


class VideoGenerationState(BaseModel):
    """Shared immutable-by-convention state that moves through LangGraph nodes."""

    file_path: str
    task_id: str
    markdown_content: str | None = None
    sections: list[ChapterSection] = Field(default_factory=list)
    storyboard_beats: list[ScriptBeat] = Field(default_factory=list)
    narrated_beats: list[NarratedBeat] = Field(default_factory=list)
    output_video_path: str | None = None
    video_url: str | None = None
    error_message: str | None = None
