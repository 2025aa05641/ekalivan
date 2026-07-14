"""Async API endpoints for persisted video-generation jobs."""

import asyncio
import logging
from collections.abc import Coroutine
from uuid import UUID

from fastapi import APIRouter, Depends, Request, status
from langgraph.graph.state import CompiledStateGraph
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.dependencies import get_db_session
from app.core.errors import TaskNotFoundError
from app.features.video_generator.models import (
    ChapterSection,
    JobStatusResponse,
    NarratedBeat,
    ScriptBeat,
    VideoGenerationRequest,
    VideoGenerationResponse,
    VideoGenerationState,
    VideoTaskStatus,
)
from app.features.video_generator.repository import VideoJobRepository
from app.features.video_generator.service import VideoGenerationService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/videos", tags=["video-generation"])


def get_video_service(session: AsyncSession = Depends(get_db_session)) -> VideoGenerationService:
    """Construct the video-generation service for the current request.

    Args:
        session: Request-scoped async database session.

    Returns:
        Service with its repository dependency injected.
    """
    return VideoGenerationService(VideoJobRepository(session))


async def run_video_generation_pipeline(
    session_factory: async_sessionmaker[AsyncSession],
    task_id: UUID,
    graph: CompiledStateGraph[VideoGenerationState],
) -> None:
    """Advance a job through the full Intake-to-Assembly stage chain.

    Args:
        session_factory: Factory that provides isolated background-task sessions.
        task_id: Job to advance through the pipeline.
        graph: Compiled LangGraph pipeline to invoke against the job's state.
    """
    async with session_factory() as session:
        repository = VideoJobRepository(session)
        job = await repository.update_status(task_id, VideoTaskStatus.PROCESSING)
        if job is None:
            return
        try:
            raw_result = await graph.ainvoke(VideoGenerationState(file_path=job.file_storage_path, task_id=str(job.id)))
            result = VideoGenerationState.model_validate(raw_result)
        except Exception as exc:
            logger.exception("Video generation pipeline failed for job %s", task_id)
            await repository.mark_failed(task_id, str(exc) or f"{type(exc).__name__} (see server logs for details)")
            return
        if (
            result.markdown_content is None
            or not result.sections
            or not result.storyboard_beats
            or not result.narrated_beats
            or result.output_video_path is None
        ):
            await repository.mark_failed(task_id, "Pipeline completed without producing the expected content.")
            return
        await repository.mark_completed(
            task_id,
            result.markdown_content,
            result.sections,
            result.storyboard_beats,
            result.narrated_beats,
            result.output_video_path,
        )


def schedule_background_task(app: Request, coroutine: Coroutine[object, object, None]) -> None:
    """Schedule and retain a background task for the application lifespan.

    Args:
        app: Request used to access application state.
        coroutine: Coroutine that runs the generation pipeline.
    """
    task = asyncio.create_task(coroutine)
    app.app.state.background_tasks.add(task)
    task.add_done_callback(app.app.state.background_tasks.discard)


@router.post("/generate", response_model=VideoGenerationResponse, status_code=status.HTTP_202_ACCEPTED)
async def generate_video(
    payload: VideoGenerationRequest,
    request: Request,
    service: VideoGenerationService = Depends(get_video_service),
) -> VideoGenerationResponse:
    """Persist a queued video job and start its background generation pipeline.

    Args:
        payload: Validated chapter details.
        request: Current FastAPI request.
        service: Injected job-creation service.

    Returns:
        UUID and queued status for the accepted job.
    """
    job = await service.create_job(payload)
    schedule_background_task(
        request,
        run_video_generation_pipeline(
            request.app.state.session_factory, job.id, request.app.state.video_generation_graph
        ),
    )
    return VideoGenerationResponse(task_id=job.id, status=VideoTaskStatus(job.status))


@router.get("/{task_id}", response_model=JobStatusResponse)
async def get_video_job_status(
    task_id: UUID,
    service: VideoGenerationService = Depends(get_video_service),
) -> JobStatusResponse:
    """Retrieve the current lifecycle state of a persisted video job.

    Args:
        task_id: UUID returned when the job was accepted.
        service: Injected job service.

    Returns:
        UUID, current status, and any Intake-stage result or failure detail.

    Raises:
        TaskNotFoundError: If the requested job does not exist.
    """
    job = await service.get_job(task_id)
    if job is None:
        raise TaskNotFoundError(str(task_id))
    sections = [ChapterSection.model_validate(section) for section in job.sections] if job.sections else None
    storyboard_beats = (
        [ScriptBeat.model_validate(beat) for beat in job.storyboard_beats] if job.storyboard_beats else None
    )
    narrated_beats = [NarratedBeat.model_validate(beat) for beat in job.narrated_beats] if job.narrated_beats else None
    return JobStatusResponse(
        task_id=job.id,
        status=VideoTaskStatus(job.status),
        markdown_content=job.markdown_content,
        sections=sections,
        storyboard_beats=storyboard_beats,
        narrated_beats=narrated_beats,
        output_video_path=job.output_video_path,
        error_message=job.error_message,
    )
