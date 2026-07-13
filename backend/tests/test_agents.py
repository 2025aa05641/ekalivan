"""ParserAgent node tests."""

import pytest

from app.core.interfaces import IMcpTool
from app.features.video_generator.agents import ParserAgent
from app.features.video_generator.models import VideoGenerationState


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
