"""MCP tool adapters wrapping external document and media binaries."""

import asyncio
from collections.abc import AsyncIterator, Callable, Mapping
from pathlib import Path
from typing import Protocol, cast

import aiofiles
import aiofiles.os
import edge_tts
import imageio_ffmpeg
from markitdown import MarkItDown
from moviepy import AudioFileClip, ColorClip, CompositeVideoClip, TextClip, concatenate_videoclips

from app.core.interfaces import IMcpTool
from app.core.retry import retry_with_backoff
from app.features.video_generator.models import WordTimestamp

_TICKS_PER_SECOND = 10_000_000


class MarkItDownTool(IMcpTool):
    """Converts a source document on disk to Markdown text via MarkItDown."""

    def __init__(self, converter: MarkItDown | None = None) -> None:
        """Create the tool with an injectable MarkItDown converter.

        Args:
            converter: Converter instance to use. Defaults to a new ``MarkItDown()``.
        """
        self._converter = converter or MarkItDown()

    async def execute(self, **kwargs: object) -> object:
        """Convert the file at ``file_path`` to Markdown off the event loop.

        Args:
            kwargs: Must contain ``file_path`` (``str``), the document to convert.

        Returns:
            The converted Markdown text.

        Raises:
            TypeError: If ``file_path`` is missing or not a string.
        """
        file_path = kwargs.get("file_path")
        if not isinstance(file_path, str):
            raise TypeError("MarkItDownTool requires a string 'file_path' argument.")
        return await asyncio.to_thread(self._convert, file_path)

    def _convert(self, file_path: str) -> str:
        """Run the blocking MarkItDown conversion.

        Args:
            file_path: Path to the source document.

        Returns:
            The converted Markdown text.
        """
        return self._converter.convert(file_path).markdown


class _CommunicateProtocol(Protocol):
    """Structural shape of ``edge_tts.Communicate`` this tool depends on."""

    def stream(self) -> AsyncIterator[Mapping[str, object]]:
        """Yield audio and word-boundary chunks for the synthesized speech."""
        ...


CommunicateFactory = Callable[[str, str], _CommunicateProtocol]


def _default_communicate_factory(text: str, voice: str) -> _CommunicateProtocol:
    """Build the real Edge TTS communicate session, requesting word-level boundaries.

    Returns:
        A live ``edge_tts.Communicate`` session for ``text`` in ``voice``.
    """
    return edge_tts.Communicate(text, voice, boundary="WordBoundary")


class EdgeTtsTool(IMcpTool):
    """Synthesizes narration audio and captures word-level timestamps via Edge TTS."""

    def __init__(
        self,
        communicate_factory: CommunicateFactory | None = None,
        *,
        max_attempts: int = 3,
        initial_retry_delay_seconds: float = 1.0,
    ) -> None:
        """Create the tool with an injectable Edge TTS communicate-session factory.

        Args:
            communicate_factory: Builds the streaming session for a given text/voice.
                Defaults to a real ``edge_tts.Communicate`` session.
            max_attempts: Total synthesis attempts before a transient failure propagates.
            initial_retry_delay_seconds: Delay before the first retry.
        """
        self._communicate_factory = communicate_factory or _default_communicate_factory
        self._max_attempts = max_attempts
        self._initial_retry_delay_seconds = initial_retry_delay_seconds

    async def execute(self, **kwargs: object) -> object:
        """Synthesize ``text`` to ``output_path`` and return its word timestamps.

        Retries the synthesis with exponential backoff on transient failures
        (network drops, empty responses from the Edge TTS service).

        Args:
            kwargs: Must contain ``text``, ``voice``, and ``output_path`` (all ``str``).

        Returns:
            Word-level timestamps captured during synthesis.

        Raises:
            TypeError: If a required argument is missing or not a string.
        """
        text = kwargs.get("text")
        voice = kwargs.get("voice")
        output_path = kwargs.get("output_path")
        if not isinstance(text, str) or not isinstance(voice, str) or not isinstance(output_path, str):
            raise TypeError("EdgeTtsTool requires string 'text', 'voice', and 'output_path' arguments.")

        await aiofiles.os.makedirs(str(Path(output_path).parent), exist_ok=True)

        async def _synthesize_once() -> list[WordTimestamp]:
            word_timestamps: list[WordTimestamp] = []
            async with aiofiles.open(output_path, "wb") as audio_file:
                async for chunk in self._communicate_factory(text, voice).stream():
                    if chunk["type"] == "audio":
                        await audio_file.write(cast(bytes, chunk["data"]))
                    elif chunk["type"] == "WordBoundary":
                        offset = cast(int, chunk["offset"])
                        duration = cast(int, chunk["duration"])
                        word_timestamps.append(
                            WordTimestamp(
                                word=str(chunk["text"]),
                                start_seconds=offset / _TICKS_PER_SECOND,
                                end_seconds=(offset + duration) / _TICKS_PER_SECOND,
                            )
                        )
            if not word_timestamps:
                raise ValueError(f"Edge TTS produced no word timestamps for voice '{voice}'.")
            return word_timestamps

        return await retry_with_backoff(
            _synthesize_once,
            max_attempts=self._max_attempts,
            initial_delay_seconds=self._initial_retry_delay_seconds,
        )


class MoviePyTool(IMcpTool):
    """Composites narrated beats into one silent-free video via MoviePy.

    Each beat becomes one scene: a solid-color background sized and timed to its
    narration audio, with the narration text burned in as a lower-third caption.
    No illustration is generated for the ``visual_prompt`` text — image generation
    is explicitly out of MVP scope (``FutureImageGenerationTool`` in the
    architecture document is a placeholder only).
    """

    def __init__(self, video_size: tuple[int, int] = (1280, 720), fps: int = 24) -> None:
        """Create the tool with its target render resolution and frame rate.

        Args:
            video_size: Output video width and height in pixels.
            fps: Output video frame rate.
        """
        self._video_size = video_size
        self._fps = fps

    async def execute(self, **kwargs: object) -> object:
        """Composite ``beats`` into one video written to ``output_path``.

        Args:
            kwargs: Must contain ``beats`` (``list`` of narrated-beat mappings with
                ``narration`` and ``audio_path``) and ``output_path`` (``str``).

        Returns:
            ``output_path``, once the composed video has been written.

        Raises:
            TypeError: If a required argument is missing or the wrong type.
        """
        beats = kwargs.get("beats")
        output_path = kwargs.get("output_path")
        if not isinstance(beats, list) or not beats or not isinstance(output_path, str):
            raise TypeError("MoviePyTool requires a non-empty list 'beats' and a string 'output_path' argument.")
        await aiofiles.os.makedirs(str(Path(output_path).parent), exist_ok=True)
        await asyncio.to_thread(self._compose, beats, output_path)
        return output_path

    def _compose(self, beats: list[object], output_path: str) -> None:
        """Render the beat clips and write the concatenated video to disk.

        Args:
            beats: Narrated-beat mappings with ``narration`` and ``audio_path`` keys.
            output_path: Destination path for the composed (not yet fast-start) video.
        """
        scenes = []
        try:
            for beat in beats:
                assert isinstance(beat, Mapping)
                audio = AudioFileClip(str(beat["audio_path"]))
                background = ColorClip(size=self._video_size, color=(30, 60, 114), duration=audio.duration)
                caption = (
                    TextClip(
                        text=str(beat["narration"]),
                        font_size=40,
                        color="white",
                        size=(self._video_size[0] - 120, None),
                        method="caption",
                    )
                    .with_duration(audio.duration)
                    .with_position(("center", "bottom"))
                )
                scenes.append(CompositeVideoClip([background, caption]).with_audio(audio))
            final = concatenate_videoclips(scenes)
            try:
                final.write_videofile(output_path, fps=self._fps, codec="libx264", audio_codec="aac", logger=None)
            finally:
                final.close()
        finally:
            for scene in scenes:
                scene.close()


class FFmpegTool(IMcpTool):
    """Re-encodes a video into a streaming-ready, fast-start MP4 via FFmpeg."""

    def __init__(
        self,
        ffmpeg_path: str | None = None,
        *,
        max_attempts: int = 3,
        initial_retry_delay_seconds: float = 1.0,
    ) -> None:
        """Create the tool with an injectable path to the FFmpeg binary.

        Args:
            ffmpeg_path: Path to the FFmpeg executable. Defaults to the static
                binary bundled by ``imageio_ffmpeg``.
            max_attempts: Total remux attempts before a transient failure propagates.
            initial_retry_delay_seconds: Delay before the first retry.
        """
        self._ffmpeg_path = ffmpeg_path or imageio_ffmpeg.get_ffmpeg_exe()
        self._max_attempts = max_attempts
        self._initial_retry_delay_seconds = initial_retry_delay_seconds

    async def execute(self, **kwargs: object) -> object:
        """Remux ``input_path`` to a fast-start MP4 at ``output_path``.

        Retries the remux with exponential backoff on transient failures.

        Args:
            kwargs: Must contain ``input_path`` and ``output_path`` (both ``str``).

        Returns:
            ``output_path``, once the fast-start remux has completed.

        Raises:
            TypeError: If a required argument is missing or not a string.
        """
        input_path = kwargs.get("input_path")
        output_path = kwargs.get("output_path")
        if not isinstance(input_path, str) or not isinstance(output_path, str):
            raise TypeError("FFmpegTool requires string 'input_path' and 'output_path' arguments.")
        await aiofiles.os.makedirs(str(Path(output_path).parent), exist_ok=True)

        async def _remux_once() -> str:
            process = await asyncio.create_subprocess_exec(
                self._ffmpeg_path,
                "-y",
                "-i",
                input_path,
                "-c",
                "copy",
                "-movflags",
                "+faststart",
                output_path,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            _, stderr = await process.communicate()
            if process.returncode != 0:
                raise RuntimeError(f"FFmpeg exited with code {process.returncode}: {stderr.decode(errors='replace')}")
            return output_path

        return await retry_with_backoff(
            _remux_once,
            max_attempts=self._max_attempts,
            initial_delay_seconds=self._initial_retry_delay_seconds,
        )
