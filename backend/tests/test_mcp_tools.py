"""MCP tool adapter tests."""

from collections.abc import AsyncIterator
from pathlib import Path

import pytest

from app.features.video_generator.mcp_tools import EdgeTtsTool, MarkItDownTool
from app.features.video_generator.models import WordTimestamp

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


class _StubCommunicate:
    """Deterministic stand-in for ``edge_tts.Communicate``'s stream output."""

    def __init__(self, chunks: list[dict[str, object]]) -> None:
        self._chunks = chunks

    async def stream(self) -> AsyncIterator[dict[str, object]]:
        for chunk in self._chunks:
            yield chunk


_SAMPLE_CHUNKS: list[dict[str, object]] = [
    {"type": "audio", "data": b"abc"},
    {"type": "WordBoundary", "offset": 1_000_000, "duration": 3_000_000, "text": "Hello"},
    {"type": "audio", "data": b"def"},
    {"type": "WordBoundary", "offset": 5_000_000, "duration": 2_000_000, "text": "world"},
]


async def test_edge_tts_execute_writes_audio_and_returns_word_timestamps(tmp_path: Path) -> None:
    """The tool writes streamed audio bytes in order and returns word-level timestamps."""
    tool = EdgeTtsTool(communicate_factory=lambda text, voice: _StubCommunicate(_SAMPLE_CHUNKS))
    output_path = tmp_path / "nested" / "beat.mp3"

    result = await tool.execute(text="Hello world", voice="en-US-AriaNeural", output_path=str(output_path))

    assert output_path.read_bytes() == b"abcdef"
    assert result == [
        WordTimestamp(word="Hello", start_seconds=0.1, end_seconds=0.4),
        WordTimestamp(word="world", start_seconds=0.5, end_seconds=0.7),
    ]


async def test_edge_tts_execute_raises_when_no_word_boundaries(tmp_path: Path) -> None:
    """The tool fails explicitly rather than returning an empty timing result."""
    tool = EdgeTtsTool(communicate_factory=lambda text, voice: _StubCommunicate([{"type": "audio", "data": b"x"}]))

    with pytest.raises(ValueError, match="no word timestamps"):
        await tool.execute(text="Hello", voice="en-US-AriaNeural", output_path=str(tmp_path / "unused.mp3"))


async def test_edge_tts_execute_requires_string_arguments() -> None:
    """The tool rejects missing or non-string 'text'/'voice'/'output_path' arguments."""
    tool = EdgeTtsTool(communicate_factory=lambda text, voice: _StubCommunicate(_SAMPLE_CHUNKS))

    with pytest.raises(TypeError):
        await tool.execute(text="Hello", voice="en-US-AriaNeural")
