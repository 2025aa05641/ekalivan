"""Agent node tests."""

import pytest

from app.core.interfaces import IMcpTool
from app.features.video_generator.agents import (
    CurriculumAgent,
    LessonPlanningAgent,
    ParserAgent,
    StoryboardAgent,
    TeacherAgent,
)
from app.features.video_generator.models import ChapterSection, ScriptBeat, VideoGenerationState
from app.features.video_generator.skills.curriculum import CurriculumSkill
from app.features.video_generator.skills.lesson_planning import LessonPlanningSkill
from app.features.video_generator.skills.storyboard import StoryboardSkill
from app.features.video_generator.skills.teacher import TeacherSkill
from tests.conftest import FakeLlmProvider


class _StubParserTool(IMcpTool):
    """Deterministic MCP tool stub for agent-level tests."""

    def __init__(self, result: object) -> None:
        self._result = result

    async def execute(self, **kwargs: object) -> object:
        return self._result


async def test_parser_agent_returns_markdown_content() -> None:
    """The agent maps a successful tool result onto the Markdown state field."""
    agent = ParserAgent(_StubParserTool("# The World of Plants"))

    update = await agent(VideoGenerationState(file_path="tests/fixtures/sample_chapter.txt"))

    assert update == {"markdown_content": "# The World of Plants"}


async def test_parser_agent_rejects_blank_content() -> None:
    """The agent fails explicitly rather than advancing the pipeline with empty content."""
    agent = ParserAgent(_StubParserTool("   "))

    with pytest.raises(ValueError, match="no content"):
        await agent(VideoGenerationState(file_path="tests/fixtures/sample_chapter.txt"))


async def test_curriculum_agent_returns_sections() -> None:
    """The agent maps the Curriculum skill's result onto the sections state field."""
    agent = CurriculumAgent(CurriculumSkill(FakeLlmProvider()))
    state = VideoGenerationState(file_path="x.pdf", markdown_content="# The World of Plants")

    update = await agent(state)

    assert update == {"sections": [ChapterSection(title="Mock Section", content="Mock content.")]}


async def test_curriculum_agent_requires_markdown_content() -> None:
    """The agent fails explicitly when the Intake stage has not run yet."""
    agent = CurriculumAgent(CurriculumSkill(FakeLlmProvider()))
    state = VideoGenerationState(file_path="x.pdf")

    with pytest.raises(ValueError, match="markdown_content"):
        await agent(state)


async def test_lesson_planning_agent_returns_paced_sections() -> None:
    """The agent maps the Lesson Planning skill's result onto the sections state field."""
    agent = LessonPlanningAgent(LessonPlanningSkill(FakeLlmProvider()))
    state = VideoGenerationState(file_path="x.pdf", sections=[ChapterSection(title="Raw", content="Raw content.")])

    update = await agent(state)

    assert update == {"sections": [ChapterSection(title="Mock Section", content="Mock content.")]}


async def test_lesson_planning_agent_requires_sections() -> None:
    """The agent fails explicitly when the Curriculum stage has not run yet."""
    agent = LessonPlanningAgent(LessonPlanningSkill(FakeLlmProvider()))
    state = VideoGenerationState(file_path="x.pdf")

    with pytest.raises(ValueError, match="Curriculum stage"):
        await agent(state)


async def test_teacher_agent_returns_localized_sections() -> None:
    """The agent maps the Teacher skill's result onto the sections state field."""
    agent = TeacherAgent(TeacherSkill(FakeLlmProvider()))
    state = VideoGenerationState(file_path="x.pdf", sections=[ChapterSection(title="Paced", content="Paced content.")])

    update = await agent(state)

    assert update == {"sections": [ChapterSection(title="Mock Section", content="Mock content.")]}


async def test_teacher_agent_requires_sections() -> None:
    """The agent fails explicitly when the Lesson Planning stage has not run yet."""
    agent = TeacherAgent(TeacherSkill(FakeLlmProvider()))
    state = VideoGenerationState(file_path="x.pdf")

    with pytest.raises(ValueError, match="Lesson Planning stage"):
        await agent(state)


async def test_storyboard_agent_returns_beats() -> None:
    """The agent maps the Storyboard skill's result onto the storyboard_beats state field."""
    agent = StoryboardAgent(StoryboardSkill(FakeLlmProvider()))
    state = VideoGenerationState(
        file_path="x.pdf", sections=[ChapterSection(title="Localized", content="Localized content.")]
    )

    update = await agent(state)

    assert update == {
        "storyboard_beats": [
            ScriptBeat(narration="Mock narration.", visual_prompt="Mock visual.", duration_seconds=5.0)
        ]
    }


async def test_storyboard_agent_requires_sections() -> None:
    """The agent fails explicitly when the Teacher stage has not run yet."""
    agent = StoryboardAgent(StoryboardSkill(FakeLlmProvider()))
    state = VideoGenerationState(file_path="x.pdf")

    with pytest.raises(ValueError, match="Teacher stage"):
        await agent(state)
