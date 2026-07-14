"""Agent node tests."""

from pathlib import Path

import pytest

from app.core.interfaces import IMcpTool
from app.features.video_generator.agents import (
    CurriculumAgent,
    LessonPlanningAgent,
    NarrationAgent,
    ParserAgent,
    PublishingAgent,
    StoryboardAgent,
    TeacherAgent,
    VideoRenderingAgent,
)
from app.features.video_generator.models import (
    ChapterSection,
    NarratedBeat,
    ScriptBeat,
    VideoGenerationState,
    WordTimestamp,
)
from app.features.video_generator.skills.curriculum import CurriculumSkill
from app.features.video_generator.skills.lesson_planning import LessonPlanningSkill
from app.features.video_generator.skills.narration import NarrationSkill
from app.features.video_generator.skills.publishing import PublishingSkill
from app.features.video_generator.skills.rendering import RenderingSkill
from app.features.video_generator.skills.storyboard import StoryboardSkill
from app.features.video_generator.skills.teacher import TeacherSkill
from tests.conftest import FakeCompositionTool, FakeEncodeTool, FakeLlmProvider, FakeStorageTool, FakeTtsTool


class _StubParserTool(IMcpTool):
    """Deterministic MCP tool stub for agent-level tests."""

    def __init__(self, result: object) -> None:
        self._result = result

    async def execute(self, **kwargs: object) -> object:
        return self._result


async def test_parser_agent_returns_markdown_content() -> None:
    """The agent maps a successful tool result onto the Markdown state field."""
    agent = ParserAgent(_StubParserTool("# The World of Plants"))
    state = VideoGenerationState(file_path="tests/fixtures/sample_chapter.txt", task_id="job-1")

    update = await agent(state)

    assert update == {"markdown_content": "# The World of Plants"}


async def test_parser_agent_rejects_blank_content() -> None:
    """The agent fails explicitly rather than advancing the pipeline with empty content."""
    agent = ParserAgent(_StubParserTool("   "))
    state = VideoGenerationState(file_path="tests/fixtures/sample_chapter.txt", task_id="job-1")

    with pytest.raises(ValueError, match="no content"):
        await agent(state)


async def test_curriculum_agent_returns_sections() -> None:
    """The agent maps the Curriculum skill's result onto the sections state field."""
    agent = CurriculumAgent(CurriculumSkill(FakeLlmProvider()))
    state = VideoGenerationState(file_path="x.pdf", task_id="job-1", markdown_content="# The World of Plants")

    update = await agent(state)

    assert update == {"sections": [ChapterSection(title="Mock Section", content="Mock content.")]}


async def test_curriculum_agent_requires_markdown_content() -> None:
    """The agent fails explicitly when the Intake stage has not run yet."""
    agent = CurriculumAgent(CurriculumSkill(FakeLlmProvider()))
    state = VideoGenerationState(file_path="x.pdf", task_id="job-1")

    with pytest.raises(ValueError, match="markdown_content"):
        await agent(state)


async def test_lesson_planning_agent_returns_paced_sections() -> None:
    """The agent maps the Lesson Planning skill's result onto the sections state field."""
    agent = LessonPlanningAgent(LessonPlanningSkill(FakeLlmProvider()))
    state = VideoGenerationState(
        file_path="x.pdf", task_id="job-1", sections=[ChapterSection(title="Raw", content="Raw content.")]
    )

    update = await agent(state)

    assert update == {"sections": [ChapterSection(title="Mock Section", content="Mock content.")]}


async def test_lesson_planning_agent_requires_sections() -> None:
    """The agent fails explicitly when the Curriculum stage has not run yet."""
    agent = LessonPlanningAgent(LessonPlanningSkill(FakeLlmProvider()))
    state = VideoGenerationState(file_path="x.pdf", task_id="job-1")

    with pytest.raises(ValueError, match="Curriculum stage"):
        await agent(state)


async def test_teacher_agent_returns_localized_sections() -> None:
    """The agent maps the Teacher skill's result onto the sections state field."""
    agent = TeacherAgent(TeacherSkill(FakeLlmProvider()))
    state = VideoGenerationState(
        file_path="x.pdf", task_id="job-1", sections=[ChapterSection(title="Paced", content="Paced content.")]
    )

    update = await agent(state)

    assert update == {"sections": [ChapterSection(title="Mock Section", content="Mock content.")]}


async def test_teacher_agent_requires_sections() -> None:
    """The agent fails explicitly when the Lesson Planning stage has not run yet."""
    agent = TeacherAgent(TeacherSkill(FakeLlmProvider()))
    state = VideoGenerationState(file_path="x.pdf", task_id="job-1")

    with pytest.raises(ValueError, match="Lesson Planning stage"):
        await agent(state)


async def test_storyboard_agent_returns_beats() -> None:
    """The agent maps the Storyboard skill's result onto the storyboard_beats state field."""
    agent = StoryboardAgent(StoryboardSkill(FakeLlmProvider()))
    state = VideoGenerationState(
        file_path="x.pdf", task_id="job-1", sections=[ChapterSection(title="Localized", content="Localized content.")]
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
    state = VideoGenerationState(file_path="x.pdf", task_id="job-1")

    with pytest.raises(ValueError, match="Teacher stage"):
        await agent(state)


async def test_narration_agent_returns_narrated_beats(tmp_path: Path) -> None:
    """The agent maps the Narration skill's result onto the narrated_beats state field."""
    agent = NarrationAgent(NarrationSkill(FakeTtsTool(), tmp_path))
    beat = ScriptBeat(narration="Plants make food.", visual_prompt="A sunlit leaf.", duration_seconds=4.0)
    state = VideoGenerationState(file_path="x.pdf", task_id="job-1", storyboard_beats=[beat])

    update = await agent(state)

    assert update == {
        "narrated_beats": [
            NarratedBeat(
                narration="Plants make food.",
                visual_prompt="A sunlit leaf.",
                duration_seconds=4.0,
                audio_path=str(tmp_path / "job-1" / "beat_000.mp3"),
                word_timestamps=[
                    WordTimestamp(
                        word="Mock",
                        start_seconds=0.0,
                        end_seconds=0.5,
                    ),
                ],
            )
        ]
    }


async def test_narration_agent_requires_storyboard_beats(tmp_path: Path) -> None:
    """The agent fails explicitly when the Storyboard stage has not run yet."""
    agent = NarrationAgent(NarrationSkill(FakeTtsTool(), tmp_path))
    state = VideoGenerationState(file_path="x.pdf", task_id="job-1")

    with pytest.raises(ValueError, match="Storyboard stage"):
        await agent(state)


async def test_video_rendering_agent_returns_output_video_path(tmp_path: Path) -> None:
    """The agent maps the Rendering skill's result onto the output_video_path state field."""
    agent = VideoRenderingAgent(RenderingSkill(FakeCompositionTool(), FakeEncodeTool(), tmp_path))
    narrated_beat = NarratedBeat(
        narration="Plants make food.", visual_prompt="A sunlit leaf.", duration_seconds=4.0, audio_path="beat.mp3"
    )
    state = VideoGenerationState(file_path="x.pdf", task_id="job-1", narrated_beats=[narrated_beat])

    update = await agent(state)

    assert update == {"output_video_path": str(tmp_path / "job-1" / "final.mp4")}


async def test_video_rendering_agent_requires_narrated_beats(tmp_path: Path) -> None:
    """The agent fails explicitly when the Narration stage has not run yet."""
    agent = VideoRenderingAgent(RenderingSkill(FakeCompositionTool(), FakeEncodeTool(), tmp_path))
    state = VideoGenerationState(file_path="x.pdf", task_id="job-1")

    with pytest.raises(ValueError, match="Narration stage"):
        await agent(state)


async def test_publishing_agent_returns_video_url(tmp_path: Path) -> None:
    """The agent maps the Publishing skill's result onto the video_url state field."""
    agent = PublishingAgent(PublishingSkill(FakeStorageTool(), tmp_path))
    state = VideoGenerationState(
        file_path="x.pdf", task_id="job-1", output_video_path=str(tmp_path / "video" / "job-1" / "final.mp4")
    )

    update = await agent(state)

    assert update == {"video_url": "/static/video/job-1/final.mp4"}


async def test_publishing_agent_requires_output_video_path(tmp_path: Path) -> None:
    """The agent fails explicitly when the Video Rendering stage has not run yet."""
    agent = PublishingAgent(PublishingSkill(FakeStorageTool(), tmp_path))
    state = VideoGenerationState(file_path="x.pdf", task_id="job-1")

    with pytest.raises(ValueError, match="Video Rendering stage"):
        await agent(state)
