"""Database repository for video-generation jobs."""

from uuid import UUID

from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.features.video_generator.db_models import VideoJob
from app.features.video_generator.models import (
    ChapterSection,
    JobMetrics,
    NarratedBeat,
    ScriptBeat,
    VideoGenerationRequest,
    VideoTaskStatus,
)


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
            file_storage_path=request.file_storage_path,
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

    async def mark_completed(
        self,
        task_id: UUID,
        markdown_content: str,
        sections: list[ChapterSection],
        storyboard_beats: list[ScriptBeat],
        narrated_beats: list[NarratedBeat],
        output_video_path: str,
        video_url: str,
    ) -> VideoJob | None:
        """Record a successful pipeline result and complete the job.

        Args:
            task_id: Video-generation job UUID.
            markdown_content: Markdown produced by the Parser agent.
            sections: Concept sections produced by the Teacher agent.
            storyboard_beats: Timed scene beats produced by the Storyboard agent.
            narrated_beats: Narrated, timed scene beats produced by the Narration agent.
            output_video_path: Final video file path produced by the Video Rendering agent.
            video_url: Public URL produced by the Publishing agent.

        Returns:
            Updated job, or ``None`` when the job does not exist.
        """
        job = await self.get_job(task_id)
        if job is None:
            return None
        job.status = VideoTaskStatus.COMPLETED.value
        job.markdown_content = markdown_content
        job.sections = [section.model_dump() for section in sections]
        job.storyboard_beats = [beat.model_dump() for beat in storyboard_beats]
        job.narrated_beats = [beat.model_dump() for beat in narrated_beats]
        job.output_video_path = output_video_path
        job.video_url = video_url
        await self._session.commit()
        await self._session.refresh(job)
        return job

    async def get_metrics(self) -> JobMetrics:
        """Aggregate job counts and completed-job durations across all persisted jobs.

        Returns:
            Total job count, per-status counts, and mean completion time in seconds
            (``None`` when no job has completed yet).
        """
        jobs = (await self._session.execute(select(VideoJob))).scalars().all()
        counts_by_status: dict[str, int] = {}
        completed_durations: list[float] = []
        for job in jobs:
            counts_by_status[job.status] = counts_by_status.get(job.status, 0) + 1
            if job.status == VideoTaskStatus.COMPLETED.value:
                completed_durations.append((job.updated_at - job.created_at).total_seconds())
        average_completion_seconds = (
            sum(completed_durations) / len(completed_durations) if completed_durations else None
        )
        return JobMetrics(
            total_jobs=len(jobs),
            counts_by_status=counts_by_status,
            average_completion_seconds=average_completion_seconds,
        )

    async def list_jobs(self, limit: int = 20) -> list[VideoJob]:
        """Return the most recently created jobs, newest first.

        Args:
            limit: Maximum number of jobs to return.

        Returns:
            Up to ``limit`` jobs ordered by ``created_at`` descending.
        """
        result = await self._session.execute(
            select(VideoJob).order_by(desc(VideoJob.created_at)).limit(limit)
        )
        return list(result.scalars().all())

    async def mark_failed(self, task_id: UUID, error_message: str) -> VideoJob | None:
        """Record a pipeline failure without raising past the background task.

        Args:
            task_id: Video-generation job UUID.
            error_message: Safe, human-readable failure description.

        Returns:
            Updated job, or ``None`` when the job does not exist.
        """
        job = await self.get_job(task_id)
        if job is None:
            return None
        job.status = VideoTaskStatus.FAILED.value
        job.error_message = error_message
        await self._session.commit()
        await self._session.refresh(job)
        return job
