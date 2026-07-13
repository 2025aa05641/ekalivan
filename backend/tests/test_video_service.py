"""Video-generation service tests."""

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.features.video_generator.models import VideoGenerationRequest, VideoTaskStatus
from app.features.video_generator.repository import VideoJobRepository
from app.features.video_generator.service import VideoGenerationService


async def test_service_creates_queued_job(session_factory: async_sessionmaker[AsyncSession]) -> None:
    """Service validates and delegates queued job creation to the repository."""
    request = VideoGenerationRequest(
        class_level="6",
        subject="Science",
        chapter_title="The World of Plants",
        file_storage_path="uploads/chapters/science_ch4.pdf",
    )
    async with session_factory() as session:
        service = VideoGenerationService(VideoJobRepository(session))
        job = await service.create_job(request)

    assert job.status == VideoTaskStatus.QUEUED.value
    assert job.class_level == "6"
