"""Agent node tests."""

import pytest

from app.core.interfaces import IMcpTool
from app.features.video_generator.agents import CurriculumAgent, ParserAgent
from app.features.video_generator.models import ChapterSection, VideoGenerationState
from app.features.video_generator.skills.curriculum import CurriculumSkill
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
