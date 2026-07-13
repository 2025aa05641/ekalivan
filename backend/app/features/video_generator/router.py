"""Async API endpoints for persisted video-generation jobs."""

import asyncio
from collections.abc import Coroutine
from uuid import UUID

from fastapi import APIRouter, Depends, Request, status
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.dependencies import get_db_session
from app.core.errors import TaskNotFoundError
from app.features.video_generator.models import (
    JobStatusResponse,
    VideoGenerationRequest,
    VideoGenerationResponse,
    VideoTaskStatus,
)
from app.features.video_generator.repository import VideoJobRepository
from app.features.video_generator.service import VideoGenerationService

router = APIRouter(prefix="/api/v1/videos", tags=["video-generation"])


def get_video_service(session: AsyncSession = Depends(get_db_session)) -> VideoGenerationService:
    """Construct the video-generation service for the current request.

    Args:
        session: Request-scoped async database session.

    Returns:
        Service with its repository dependency injected.
    """
    return VideoGenerationService(VideoJobRepository(session))


async def mock_video_generation(
    session_factory: async_sessionmaker[AsyncSession],
    task_id: UUID,
    delay_seconds: float,
) -> None:
    """Advance a job through the temporary mock generation lifecycle.

    Args:
        session_factory: Factory that provides isolated background-task sessions.
        task_id: Job to advance through the lifecycle.
        delay_seconds: Delay between status transitions.
    """
    async with session_factory() as session:
        repository = VideoJobRepository(session)
        await asyncio.sleep(delay_seconds)
        updated = await repository.update_status(task_id, VideoTaskStatus.PROCESSING)
        if updated is None:
            return
        await asyncio.sleep(delay_seconds)
        await repository.update_status(task_id, VideoTaskStatus.COMPLETED)


def schedule_background_task(app: Request, coroutine: Coroutine[object, object, None]) -> None:
    """Schedule and retain a mock background task for the application lifespan.

    Args:
        app: Request used to access application state.
        coroutine: Coroutine that runs the mock status lifecycle.
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
    """Persist a queued video job and start its mock background lifecycle.

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
        mock_video_generation(request.app.state.session_factory, job.id, request.app.state.mock_job_delay_seconds),
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
        UUID and current job status.

    Raises:
        TaskNotFoundError: If the requested job does not exist.
    """
    job = await service.get_job(task_id)
    if job is None:
        raise TaskNotFoundError(str(task_id))
    return JobStatusResponse(task_id=job.id, status=VideoTaskStatus(job.status))
