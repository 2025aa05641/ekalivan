"""MCP tool adapter tests."""

from collections.abc import AsyncIterator
from pathlib import Path

import pytest

from app.features.video_generator.mcp_tools import EdgeTtsTool, FFmpegTool, MarkItDownTool, MoviePyTool
from app.features.video_generator.models import WordTimestamp

FIXTURE_PATH = str(Path(__file__).parent / "fixtures" / "sample_chapter.txt")
SILENT_AUDIO_FIXTURE_PATH = str(Path(__file__).parent / "fixtures" / "silent_beat.wav")


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


_TEST_BEATS = [
    {"narration": "Plants make their own food.", "audio_path": SILENT_AUDIO_FIXTURE_PATH},
    {"narration": "They use sunlight to do it.", "audio_path": SILENT_AUDIO_FIXTURE_PATH},
]


async def test_moviepy_execute_composites_beats_into_a_video(tmp_path: Path) -> None:
    """The tool writes one real, playable video composed from multiple beats."""
    tool = MoviePyTool(video_size=(320, 240), fps=10)
    output_path = tmp_path / "nested" / "composed.mp4"

    result = await tool.execute(beats=_TEST_BEATS, output_path=str(output_path))

    assert result == str(output_path)
    assert output_path.exists()
    assert output_path.stat().st_size > 0


async def test_moviepy_execute_requires_beats_and_output_path() -> None:
    """The tool rejects a missing/empty 'beats' list or a non-string 'output_path'."""
    tool = MoviePyTool()

    with pytest.raises(TypeError):
        await tool.execute(beats=[], output_path="unused.mp4")


async def test_ffmpeg_execute_produces_a_faststart_video(tmp_path: Path) -> None:
    """The tool remuxes a real composed video into a fast-start MP4."""
    composed_path = tmp_path / "composed.mp4"
    await MoviePyTool(video_size=(320, 240), fps=10).execute(beats=_TEST_BEATS, output_path=str(composed_path))
    final_path = tmp_path / "final.mp4"

    result = await FFmpegTool().execute(input_path=str(composed_path), output_path=str(final_path))

    assert result == str(final_path)
    assert final_path.exists()
    assert final_path.stat().st_size > 0


async def test_ffmpeg_execute_raises_for_missing_input(tmp_path: Path) -> None:
    """The tool raises a clear error when FFmpeg fails to process the input."""
    with pytest.raises(RuntimeError, match="FFmpeg exited"):
        await FFmpegTool().execute(
            input_path=str(tmp_path / "does_not_exist.mp4"), output_path=str(tmp_path / "final.mp4")
        )


async def test_ffmpeg_execute_requires_string_arguments() -> None:
    """The tool rejects a missing or non-string 'input_path'/'output_path' argument."""
    with pytest.raises(TypeError):
        await FFmpegTool().execute(input_path="only_one_argument.mp4")
