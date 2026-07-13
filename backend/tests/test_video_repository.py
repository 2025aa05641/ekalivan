"""Repository persistence tests."""

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.features.video_generator.models import VideoGenerationRequest, VideoTaskStatus
from app.features.video_generator.repository import VideoJobRepository


async def test_repository_creates_reads_and_updates_job(session_factory: async_sessionmaker[AsyncSession]) -> None:
    """Repository persists a queued job and updates its status asynchronously."""
    request = VideoGenerationRequest(
        class_level="6",
        subject="Science",
        chapter_title="The World of Plants",
        file_storage_path="uploads/chapters/science_ch4.pdf",
    )
    async with session_factory() as session:
        repository = VideoJobRepository(session)
        created = await repository.create_job(request)
        fetched = await repository.get_job(created.id)
        assert fetched is not None
        assert fetched.status == VideoTaskStatus.QUEUED.value
        updated = await repository.update_status(created.id, VideoTaskStatus.PROCESSING)

    assert updated is not None
    assert updated.status == VideoTaskStatus.PROCESSING.value
