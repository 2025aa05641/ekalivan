"""CurriculumSkill tests."""

from app.features.video_generator.models import ChapterSection
from app.features.video_generator.skills.curriculum import CurriculumSkill
from tests.conftest import FakeLlmProvider


async def test_structure_chapter_returns_sections_from_provider() -> None:
    """The skill maps the provider's validated response onto ChapterSection objects."""
    provider = FakeLlmProvider()
    skill = CurriculumSkill(provider)

    sections = await skill.structure_chapter("# The World of Plants\n\nPlants make food using sunlight.")

    assert sections == [ChapterSection(title="Mock Section", content="Mock content.")]
    assert provider.last_prompt is not None
    assert "Plants make food using sunlight." in provider.last_prompt
