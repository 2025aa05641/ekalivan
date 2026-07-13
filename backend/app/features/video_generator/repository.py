"""Database repository for video-generation jobs."""

from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.features.video_generator.db_models import VideoJob
from app.features.video_generator.models import VideoGenerationRequest, VideoTaskStatus


class VideoJobRepository:
    """Encapsulate async persistence operations for ``VideoJob`` records."""

    def __init__(self, session: AsyncSession) -> None:
        """Create the repository with a request-scoped database session.

        Args:
            session: Async SQLAlchemy session provided by dependency injection.
        """
        self._session = session

    async def create_job(self, request: VideoGenerationRequest) -> VideoJob:
        """Create and commit a queued video-generation job.

        Args:
            request: Validated video-generation input.

        Returns:
            Persisted job with its generated UUID and timestamps.
        """
        job = VideoJob(
            class_level=request.class_level,
            subject=request.subject,
            chapter_title=request.chapter_title,
            status=VideoTaskStatus.QUEUED.value,
        )
        self._session.add(job)
        await self._session.commit()
        await self._session.refresh(job)
        return job

    async def get_job(self, task_id: UUID) -> VideoJob | None:
        """Retrieve a video job by its UUID.

        Args:
            task_id: Video-generation job UUID.

        Returns:
            Persisted job, or ``None`` when the job does not exist.
        """
        return await self._session.get(VideoJob, task_id)

    async def update_status(self, task_id: UUID, status: VideoTaskStatus) -> VideoJob | None:
        """Update a job status and commit the state transition.

        Args:
            task_id: Video-generation job UUID.
            status: New lifecycle status.

        Returns:
            Updated job, or ``None`` when the job does not exist.
        """
        job = await self.get_job(task_id)
        if job is None:
            return None
        job.status = status.value
        await self._session.commit()
        await self._session.refresh(job)
        return job
