"""MCP tool adapter tests."""

from collections.abc import AsyncIterator, Callable
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import pytest
from google.genai import errors as genai_errors

from app.features.video_generator.mcp_tools import (
    EdgeTtsTool,
    FFmpegTool,
    MarkItDownTool,
    MoviePyTool,
    VeoVideoGenerationTool,
)
from app.features.video_generator.models import WordTimestamp
from app.features.video_generator.skills.rendering import clip_cache_key

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
    tool = EdgeTtsTool(
        communicate_factory=lambda text, voice: _StubCommunicate([{"type": "audio", "data": b"x"}]),
        max_attempts=1,
    )

    with pytest.raises(ValueError, match="no word timestamps"):
        await tool.execute(text="Hello", voice="en-US-AriaNeural", output_path=str(tmp_path / "unused.mp3"))


async def test_edge_tts_execute_requires_string_arguments() -> None:
    """The tool rejects missing or non-string 'text'/'voice'/'output_path' arguments."""
    tool = EdgeTtsTool(communicate_factory=lambda text, voice: _StubCommunicate(_SAMPLE_CHUNKS))

    with pytest.raises(TypeError):
        await tool.execute(text="Hello", voice="en-US-AriaNeural")


_TEST_BEATS = [
    {
        "narration": "Plants make their own food.",
        "visual_prompt": "A plant in a pot under the sun.",
        "audio_path": SILENT_AUDIO_FIXTURE_PATH,
    },
    {
        "narration": "They use sunlight to do it.",
        "visual_prompt": "An arrow connecting sunlight to a leaf.",
        "audio_path": SILENT_AUDIO_FIXTURE_PATH,
    },
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


async def test_moviepy_execute_rejects_non_dict_clip_paths() -> None:
    """The tool rejects a 'clip_paths' argument that isn't a dict."""
    tool = MoviePyTool()

    with pytest.raises(TypeError):
        await tool.execute(beats=_TEST_BEATS, output_path="unused.mp4", clip_paths=["not", "a", "dict"])


async def test_moviepy_execute_uses_a_provided_clip_as_the_background(tmp_path: Path) -> None:
    """A beat whose visual_prompt key is in 'clip_paths' uses that real clip, not the drawn icon."""
    tool = MoviePyTool(video_size=(320, 240), fps=10)
    # Any real, playable video works as the "Veo clip" stand-in — reuse the icon-drawn
    # path to produce one without needing a checked-in binary fixture.
    source_clip_path = tmp_path / "source_clip.mp4"
    await tool.execute(beats=_TEST_BEATS[:1], output_path=str(source_clip_path))

    output_path = tmp_path / "composed.mp4"
    clip_paths = {clip_cache_key(_TEST_BEATS[0]["visual_prompt"]): str(source_clip_path)}

    result = await tool.execute(beats=_TEST_BEATS, output_path=str(output_path), clip_paths=clip_paths)

    assert result == str(output_path)
    assert output_path.exists()
    assert output_path.stat().st_size > 0


@dataclass
class _FakeVideo:
    """Stand-in for ``genai.types.Video`` distinguishable across extension calls."""

    marker: str


@dataclass
class _GeneratedVideo:
    video: _FakeVideo


@dataclass
class _Response:
    generated_videos: list[_GeneratedVideo]


class _FakeOperation:
    """Stand-in for a completed ``genai.types.GenerateVideosOperation``."""

    def __init__(self, video: _FakeVideo | None, *, error: str | None = None) -> None:
        self.done = True
        self.error = error
        self.response = _Response([_GeneratedVideo(video)]) if video is not None else None


class _FakeModels:
    """Records every ``generate_videos`` call and replays scripted responses/errors."""

    def __init__(self, on_generate: Callable[..., _FakeOperation]) -> None:
        self.calls: list[dict[str, Any]] = []
        self._on_generate = on_generate

    def generate_videos(
        self, *, model: str, prompt: str, video: _FakeVideo | None = None, config: object = None
    ) -> _FakeOperation:
        self.calls.append({"model": model, "prompt": prompt, "video": video, "config": config})
        return self._on_generate(video=video, call_index=len(self.calls) - 1)


class _FakeOperations:
    """Operations are always pre-completed by ``_FakeModels``, so ``get`` is never exercised."""

    def get(self, operation: _FakeOperation) -> _FakeOperation:
        return operation


class _FakeFiles:
    def __init__(self, bytes_by_marker: dict[str, bytes]) -> None:
        self._bytes_by_marker = bytes_by_marker

    def download(self, *, file: _FakeVideo) -> bytes:
        return self._bytes_by_marker[file.marker]


class _FakeGenaiClient:
    def __init__(self, models: _FakeModels, files: _FakeFiles) -> None:
        self.models = models
        self.operations = _FakeOperations()
        self.files = files


async def test_veo_execute_extends_a_clip_to_cover_the_beats_duration(tmp_path: Path) -> None:
    """A beat longer than 8s gets one extension call, and the final clip is downloaded."""
    initial_video = _FakeVideo("initial")
    extended_video = _FakeVideo("extended")

    def on_generate(*, video: _FakeVideo | None, call_index: int) -> _FakeOperation:
        return _FakeOperation(initial_video if video is None else extended_video)

    models = _FakeModels(on_generate)
    files = _FakeFiles({"initial": b"initial-bytes", "extended": b"extended-bytes"})
    tool = VeoVideoGenerationTool(_FakeGenaiClient(models, files), "veo-3.1-fast-generate-preview")
    beats = [{"id": "beat-1", "visual_prompt": "a sunlit leaf", "duration_seconds": 13.0}]

    clip_paths = await tool.execute(beats=beats, cache_dir=str(tmp_path))

    assert clip_paths == {"beat-1": str(tmp_path / "beat-1.mp4")}
    assert (tmp_path / "beat-1.mp4").read_bytes() == b"extended-bytes"
    assert len(models.calls) == 2
    assert models.calls[0]["video"] is None
    assert models.calls[0]["config"].duration_seconds == 8
    assert models.calls[1]["video"] is initial_video
    assert tool.budget_exhausted is False


async def test_veo_execute_does_not_extend_a_clip_within_8_seconds(tmp_path: Path) -> None:
    """A beat under 8s stops after the initial call — no extension is requested."""
    result_video = _FakeVideo("only")
    models = _FakeModels(lambda *, video, call_index: _FakeOperation(result_video))
    files = _FakeFiles({"only": b"only-bytes"})
    tool = VeoVideoGenerationTool(_FakeGenaiClient(models, files), "veo-3.1-fast-generate-preview")
    beats = [{"id": "beat-1", "visual_prompt": "a sunlit leaf", "duration_seconds": 5.0}]

    clip_paths = await tool.execute(beats=beats, cache_dir=str(tmp_path))

    assert clip_paths == {"beat-1": str(tmp_path / "beat-1.mp4")}
    assert len(models.calls) == 1


async def test_veo_execute_salvages_the_initial_clip_when_extension_hits_a_billing_error(tmp_path: Path) -> None:
    """A beat whose extension fails on billing still uses its already-paid-for initial clip."""
    initial_video = _FakeVideo("initial")

    def on_generate(*, video: _FakeVideo | None, call_index: int) -> _FakeOperation:
        if video is None:
            return _FakeOperation(initial_video)
        raise genai_errors.ClientError(code=429, response_json={"message": "quota exceeded"})

    models = _FakeModels(on_generate)
    files = _FakeFiles({"initial": b"initial-bytes"})
    tool = VeoVideoGenerationTool(_FakeGenaiClient(models, files), "veo-3.1-fast-generate-preview")
    beats = [
        {"id": "beat-1", "visual_prompt": "a sunlit leaf", "duration_seconds": 13.0},
        {"id": "beat-2", "visual_prompt": "a growing plant", "duration_seconds": 5.0},
    ]

    clip_paths = await tool.execute(beats=beats, cache_dir=str(tmp_path))

    assert clip_paths == {"beat-1": str(tmp_path / "beat-1.mp4")}
    assert (tmp_path / "beat-1.mp4").read_bytes() == b"initial-bytes"
    assert tool.budget_exhausted is True
    assert len(models.calls) == 2  # beat-1's initial + failed extension; beat-2 never attempted


async def test_veo_execute_stops_remaining_beats_after_a_billing_error(tmp_path: Path) -> None:
    """Once billing/quota is exhausted, later beats are skipped instead of attempted."""

    def on_generate(*, video: _FakeVideo | None, call_index: int) -> _FakeOperation:
        raise genai_errors.ClientError(code=429, response_json={"message": "quota exceeded"})

    models = _FakeModels(on_generate)
    tool = VeoVideoGenerationTool(_FakeGenaiClient(models, _FakeFiles({})), "veo-3.1-fast-generate-preview")
    beats = [
        {"id": "beat-1", "visual_prompt": "a sunlit leaf", "duration_seconds": 5.0},
        {"id": "beat-2", "visual_prompt": "a growing plant", "duration_seconds": 5.0},
    ]

    clip_paths = await tool.execute(beats=beats, cache_dir=str(tmp_path))

    assert clip_paths == {}
    assert tool.budget_exhausted is True
    assert len(models.calls) == 1  # beat-2 was never attempted


async def test_veo_execute_falls_back_to_later_beats_on_a_non_billing_error(tmp_path: Path) -> None:
    """A beat that fails for a reason other than billing/quota is skipped, not fatal."""
    good_video = _FakeVideo("good")

    def on_generate(*, video: _FakeVideo | None, call_index: int) -> _FakeOperation:
        if len(models.calls) == 1:
            raise RuntimeError("safety-filtered")
        return _FakeOperation(good_video)

    models = _FakeModels(on_generate)
    files = _FakeFiles({"good": b"good-bytes"})
    tool = VeoVideoGenerationTool(_FakeGenaiClient(models, files), "veo-3.1-fast-generate-preview")
    beats = [
        {"id": "beat-1", "visual_prompt": "a sunlit leaf", "duration_seconds": 5.0},
        {"id": "beat-2", "visual_prompt": "a growing plant", "duration_seconds": 5.0},
    ]

    clip_paths = await tool.execute(beats=beats, cache_dir=str(tmp_path))

    assert clip_paths == {"beat-2": str(tmp_path / "beat-2.mp4")}
    assert tool.budget_exhausted is False


async def test_veo_execute_requires_beats_list_and_cache_dir() -> None:
    """The tool rejects a missing/wrong-typed 'beats' or 'cache_dir' argument."""
    unused_operation = _FakeOperation(_FakeVideo("unused"))
    client = _FakeGenaiClient(_FakeModels(lambda **_: unused_operation), _FakeFiles({}))
    tool = VeoVideoGenerationTool(client, "veo-3.1-fast-generate-preview")

    with pytest.raises(TypeError):
        await tool.execute(beats="not-a-list", cache_dir="unused")


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
        await FFmpegTool(max_attempts=1).execute(
            input_path=str(tmp_path / "does_not_exist.mp4"), output_path=str(tmp_path / "final.mp4")
        )


async def test_ffmpeg_execute_requires_string_arguments() -> None:
    """The tool rejects a missing or non-string 'input_path'/'output_path' argument."""
    with pytest.raises(TypeError):
        await FFmpegTool().execute(input_path="only_one_argument.mp4")
