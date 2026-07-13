"""MarkItDownTool adapter tests."""

from pathlib import Path

import pytest

from app.features.video_generator.mcp_tools import MarkItDownTool

FIXTURE_PATH = str(Path(__file__).parent / "fixtures" / "sample_chapter.txt")


async def test_execute_converts_file_to_markdown() -> None:
    """The tool converts a real document into non-empty Markdown text."""
    tool = MarkItDownTool()

    result = await tool.execute(file_path=FIXTURE_PATH)

    assert isinstance(result, str)
    assert "Plants make their own food" in result


async def test_execute_raises_for_missing_file() -> None:
    """The tool propagates a clear error for a source file that does not exist."""
    tool = MarkItDownTool()

    with pytest.raises(FileNotFoundError):
        await tool.execute(file_path="tests/fixtures/does_not_exist.txt")


async def test_execute_requires_string_file_path() -> None:
    """The tool rejects a missing or non-string 'file_path' argument."""
    tool = MarkItDownTool()

    with pytest.raises(TypeError):
        await tool.execute()
