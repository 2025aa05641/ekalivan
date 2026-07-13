"""Application service for video-generation job creation."""

from uuid import UUID

from app.features.video_generator.db_models import VideoJob
from app.features.video_generator.models import VideoGenerationRequest
from app.features.video_generator.repository import VideoJobRepository


class VideoGenerationService:
    """Coordinate request validation and durable video-job creation."""

    def __init__(self, repository: VideoJobRepository) -> None:
        """Create the service with its persistence dependency.

        Args:
            repository: Repository responsible for job storage.
        """
        self._repository = repository

    async def create_job(self, request: VideoGenerationRequest) -> VideoJob:
        """Validate the request and persist a queued job.

        Args:
            request: Pydantic-validated video-generation request.

        Returns:
            Newly created queued job.

        Raises:
            ValueError: If any required input is empty after normalization.
        """
        if not all((request.class_level, request.subject, request.chapter_title)):
            raise ValueError("Video generation fields must not be empty.")
        return await self._repository.create_job(request)

    async def get_job(self, task_id: UUID) -> VideoJob | None:
        """Retrieve a persisted job by its task identifier.

        Args:
            task_id: UUID returned when the job was created.

        Returns:
            Matching job, or ``None`` if no job exists.
        """
        return await self._repository.get_job(task_id)
