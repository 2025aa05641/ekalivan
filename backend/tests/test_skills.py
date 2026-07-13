"""Skills layer tests."""

from app.features.video_generator.models import ChapterSection, ScriptBeat
from app.features.video_generator.skills.curriculum import CurriculumSkill
from app.features.video_generator.skills.lesson_planning import LessonPlanningSkill
from app.features.video_generator.skills.storyboard import StoryboardSkill
from app.features.video_generator.skills.teacher import TeacherSkill
from tests.conftest import FakeLlmProvider


async def test_structure_chapter_returns_sections_from_provider() -> None:
    """CurriculumSkill maps the provider's validated response onto ChapterSection objects."""
    provider = FakeLlmProvider()
    skill = CurriculumSkill(provider)

    sections = await skill.structure_chapter("# The World of Plants\n\nPlants make food using sunlight.")

    assert sections == [ChapterSection(title="Mock Section", content="Mock content.")]
    assert provider.last_prompt is not None
    assert "Plants make food using sunlight." in provider.last_prompt


async def test_apply_pacing_returns_sections_from_provider() -> None:
    """LessonPlanningSkill sends the input sections and returns the provider's response."""
    provider = FakeLlmProvider()
    skill = LessonPlanningSkill(provider)
    raw_sections = [ChapterSection(title="Photosynthesis", content="Plants make food using sunlight.")]

    sections = await skill.apply_pacing(raw_sections)

    assert sections == [ChapterSection(title="Mock Section", content="Mock content.")]
    assert provider.last_prompt is not None
    assert "Plants make food using sunlight." in provider.last_prompt


async def test_localize_sections_returns_sections_from_provider() -> None:
    """TeacherSkill sends the input sections and returns the provider's response."""
    provider = FakeLlmProvider()
    skill = TeacherSkill(provider)
    raw_sections = [ChapterSection(title="Photosynthesis", content="Plants make food using sunlight.")]

    sections = await skill.localize_sections(raw_sections)

    assert sections == [ChapterSection(title="Mock Section", content="Mock content.")]
    assert provider.last_prompt is not None
    assert "Plants make food using sunlight." in provider.last_prompt


async def test_create_storyboard_returns_beats_from_provider() -> None:
    """StoryboardSkill sends the input sections and returns the provider's beats response."""
    provider = FakeLlmProvider()
    skill = StoryboardSkill(provider)
    raw_sections = [ChapterSection(title="Photosynthesis", content="Plants make food using sunlight.")]

    beats = await skill.create_storyboard(raw_sections)

    assert beats == [ScriptBeat(narration="Mock narration.", visual_prompt="Mock visual.", duration_seconds=5.0)]
    assert provider.last_prompt is not None
    assert "Plants make food using sunlight." in provider.last_prompt
