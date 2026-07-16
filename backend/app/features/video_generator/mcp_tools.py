"""MCP tool adapters wrapping external document and media binaries."""

import asyncio
import logging
from collections.abc import AsyncIterator, Callable, Mapping
from pathlib import Path
from typing import Protocol, cast

import aiofiles
import aiofiles.os
import edge_tts
import imageio_ffmpeg
import numpy as np
from google.genai import errors as genai_errors
from google.genai import types as genai_types
from markitdown import MarkItDown
from moviepy import (
    AudioFileClip,
    ColorClip,
    CompositeVideoClip,
    ImageClip,
    TextClip,
    VideoFileClip,
    concatenate_videoclips,
)
from moviepy.video import fx as vfx
from moviepy.video.VideoClip import VideoClip

from app.core.interfaces import IMcpTool
from app.core.retry import retry_with_backoff
from app.features.video_generator import icon_library
from app.features.video_generator.models import WordTimestamp
from app.features.video_generator.skills.rendering import clip_cache_key

logger = logging.getLogger(__name__)

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


# HTTP statuses that mean "this account can't pay for more generations right now"
# (quota exhausted, billing disabled) as opposed to a transient or per-request failure.
_BILLING_EXHAUSTED_CODES = frozenset({402, 403, 429})

# The Veo API only accepts 4, 6, or 8 as the initial clip's duration_seconds; 8 gives the
# most footage per call and is required if the clip is later extended.
_VEO_INITIAL_DURATION_SECONDS = 8
# Video extension always adds exactly this many seconds, regardless of what's requested.
_VEO_EXTENSION_SECONDS = 7


class VeoBudgetExhaustedError(Exception):
    """Raised internally when the Veo account can't be billed for more generations."""


class _VeoModelsProtocol(Protocol):
    """Structural shape of ``genai.Client.models`` this tool depends on."""

    def generate_videos(
        self,
        *,
        model: str,
        prompt: str,
        video: genai_types.Video | None = None,
        config: genai_types.GenerateVideosConfig | None = None,
    ) -> genai_types.GenerateVideosOperation:
        """Start a generate-videos long-running operation."""
        ...


class _VeoOperationsProtocol(Protocol):
    """Structural shape of ``genai.Client.operations`` this tool depends on."""

    def get(self, operation: genai_types.GenerateVideosOperation) -> genai_types.GenerateVideosOperation:
        """Fetch the current state of a long-running operation."""
        ...


class _VeoFilesProtocol(Protocol):
    """Structural shape of ``genai.Client.files`` this tool depends on."""

    def download(self, *, file: genai_types.Video) -> bytes:
        """Download a generated video's bytes."""
        ...


class VeoClientProtocol(Protocol):
    """Structural shape of ``genai.Client`` this tool depends on, for testability.

    Declared with read-only ``@property`` members (rather than plain attribute
    annotations) so both the real ``genai.Client`` — whose ``models``/``operations``/
    ``files`` are read-only properties — and a plain test double with simple instance
    attributes satisfy this Protocol.
    """

    @property
    def models(self) -> _VeoModelsProtocol: ...

    @property
    def operations(self) -> _VeoOperationsProtocol: ...

    @property
    def files(self) -> _VeoFilesProtocol: ...


class VeoVideoGenerationTool(IMcpTool):
    """Generates real Veo video footage per beat, extending past the native 8s cap.

    Each beat gets an initial 8-second clip, then as many 7-second extensions as needed
    to cover its narration length (Veo bills per second of video actually generated, so a
    beat under 8s costs the same as one needing several extensions up to that point).
    Stops generating further beats the moment the account can't be billed anymore
    (quota exhausted, billing disabled) and reports how far it got, rather than failing
    the whole render job — beats it didn't reach fall back to the local icon animation.
    """

    def __init__(self, client: VeoClientProtocol, model: str, *, poll_interval_seconds: float = 10.0) -> None:
        """Create the tool with an injectable Gemini API client.

        Args:
            client: Configured ``genai.Client`` (API-key authenticated), or any object
                with matching ``models``/``operations``/``files`` members (for tests).
            model: Veo model id, e.g. ``"veo-3.1-fast-generate-preview"``.
            poll_interval_seconds: Delay between long-running-operation status checks.
        """
        self._client = client
        self._model = model
        self._poll_interval_seconds = poll_interval_seconds
        self.budget_exhausted = False

    async def execute(self, **kwargs: object) -> object:
        """Generate one clip per beat, stopping early if the account runs out of budget.

        Args:
            kwargs: Must contain ``beats`` (list of mappings with ``id``, ``visual_prompt``,
                and ``duration_seconds``) and ``cache_dir`` (``str``) to write clips into.

        Returns:
            A ``dict`` mapping each beat's ``id`` to its downloaded clip's local path.
            Beats skipped after budget exhaustion, or whose generation failed outright,
            are simply absent from the mapping.

        Raises:
            TypeError: If a required argument is missing or the wrong type.
        """
        beats = kwargs.get("beats")
        cache_dir = kwargs.get("cache_dir")
        if not isinstance(beats, list) or not isinstance(cache_dir, str):
            raise TypeError("VeoVideoGenerationTool requires a list 'beats' and a string 'cache_dir' argument.")
        await aiofiles.os.makedirs(cache_dir, exist_ok=True)

        clip_paths: dict[str, str] = {}
        for beat in beats:
            assert isinstance(beat, Mapping)
            beat_id = str(beat["id"])
            if self.budget_exhausted:
                logger.info("Skipping Veo generation for beat %s: budget already exhausted.", beat_id)
                continue
            try:
                clip_path = await self._generate_one(beat, cache_dir)
            except Exception:
                logger.warning(
                    "Veo generation failed for beat %s; it will use the local fallback.", beat_id, exc_info=True
                )
                continue
            if clip_path is not None:
                clip_paths[beat_id] = clip_path
        return clip_paths

    async def _generate_one(self, beat: Mapping[str, object], cache_dir: str) -> str | None:
        """Generate (and extend, if needed) one beat's clip and download it to disk.

        If billing/quota runs out partway through extending a beat, the already-paid-for
        clip generated so far is still downloaded and used (trimmed short) rather than
        discarded — only a beat whose very first call fails returns nothing.

        Args:
            beat: Mapping with ``id``, ``visual_prompt``, and ``duration_seconds``.
            cache_dir: Directory to write the downloaded clip into.

        Returns:
            The local path of the downloaded clip, or ``None`` if nothing was generated
            (also sets ``self.budget_exhausted`` when the cause was billing/quota).
        """
        beat_id = str(beat["id"])
        prompt = str(beat["visual_prompt"])
        target_seconds = float(cast(float, beat["duration_seconds"]))

        try:
            operation = await self._call_generate(
                prompt=prompt,
                config=genai_types.GenerateVideosConfig(
                    duration_seconds=_VEO_INITIAL_DURATION_SECONDS,
                    aspect_ratio="16:9",
                    resolution="720p",
                    negative_prompt="blurry, low quality, distorted, watermark, text captions, subtitles",
                ),
            )
            operation = await self._await_operation(operation)
        except VeoBudgetExhaustedError:
            self.budget_exhausted = True
            logger.warning("Veo generation stopped at beat %s: account can't be billed for more.", beat_id)
            return None
        video = self._first_video(operation, beat_id)
        covered_seconds = float(_VEO_INITIAL_DURATION_SECONDS)

        while covered_seconds < target_seconds:
            try:
                operation = await self._call_generate(
                    prompt=prompt,
                    video=video,
                    config=genai_types.GenerateVideosConfig(resolution="720p"),
                )
                operation = await self._await_operation(operation)
            except VeoBudgetExhaustedError:
                self.budget_exhausted = True
                logger.warning(
                    "Veo extension stopped at beat %s: account can't be billed for more (keeping the %.0fs "
                    "clip generated so far).",
                    beat_id,
                    covered_seconds,
                )
                break
            video = self._first_video(operation, beat_id)
            covered_seconds += _VEO_EXTENSION_SECONDS

        clip_path = str(Path(cache_dir) / f"{beat_id}.mp4")
        video_bytes = await asyncio.to_thread(self._client.files.download, file=video)
        async with aiofiles.open(clip_path, "wb") as clip_file:
            await clip_file.write(video_bytes)
        return clip_path

    async def _call_generate(
        self,
        *,
        prompt: str,
        config: genai_types.GenerateVideosConfig,
        video: genai_types.Video | None = None,
    ) -> genai_types.GenerateVideosOperation:
        """Start one generate-videos call, translating billing errors to a stop signal.

        Args:
            prompt: Text prompt (also required on extension calls).
            config: Generation config for this call.
            video: Previously generated video to extend, or ``None`` for an initial call.

        Returns:
            The started (not yet complete) long-running operation.

        Raises:
            VeoBudgetExhaustedError: If the account can't be billed for this call.
            ClientError: For any other (non-billing) client-side API error.
        """
        try:
            return await asyncio.to_thread(
                self._client.models.generate_videos, model=self._model, prompt=prompt, video=video, config=config
            )
        except genai_errors.ClientError as exc:
            if exc.code in _BILLING_EXHAUSTED_CODES:
                raise VeoBudgetExhaustedError(str(exc)) from exc
            raise

    async def _await_operation(
        self, operation: genai_types.GenerateVideosOperation
    ) -> genai_types.GenerateVideosOperation:
        """Poll a long-running operation until it completes.

        Args:
            operation: The operation to poll.

        Returns:
            The completed operation.

        Raises:
            VeoBudgetExhaustedError: If polling surfaces a billing/quota error.
            ClientError: For any other (non-billing) client-side API error.
            RuntimeError: If the operation completes with an error.
        """
        while not operation.done:
            await asyncio.sleep(self._poll_interval_seconds)
            try:
                operation = await asyncio.to_thread(self._client.operations.get, operation)
            except genai_errors.ClientError as exc:
                if exc.code in _BILLING_EXHAUSTED_CODES:
                    raise VeoBudgetExhaustedError(str(exc)) from exc
                raise
        if operation.error:
            raise RuntimeError(f"Veo generation failed: {operation.error}")
        return operation

    def _first_video(self, operation: genai_types.GenerateVideosOperation, beat_id: str) -> genai_types.Video:
        """Extract the first generated video from a completed operation.

        Args:
            operation: A completed, error-free operation.
            beat_id: Owning beat's id, for the error message if generation was filtered.

        Returns:
            The generated ``Video`` object.

        Raises:
            RuntimeError: If no video was returned (e.g. blocked by safety filtering).
        """
        generated = operation.response.generated_videos if operation.response else None
        if not generated or generated[0].video is None:
            raise RuntimeError(f"Veo returned no video for beat {beat_id} (possibly safety-filtered).")
        return generated[0].video


class MoviePyTool(IMcpTool):
    """Composites narrated beats into one animated, illustrated video via MoviePy.

    Each beat becomes one scene: a background and the narration text burned in as a
    lower-third caption. The background is a real Veo-generated clip (looped/letterboxed
    to the beat's duration) when ``execute`` is given a matching entry in ``clip_paths``;
    otherwise it falls back to a programmatically drawn vector-style icon chosen from the
    beat's ``visual_prompt`` (see ``icon_library``) with a Ken Burns zoom-and-pan, a soft
    highlight glow, and an optional connecting-arrow overlay — fully offline and free of
    per-frame generation cost, so a render never fails just because Veo is unavailable or
    out of budget for that beat.
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
                ``narration``, ``visual_prompt``, and ``audio_path``) and
                ``output_path`` (``str``). May also contain ``clip_paths`` (``dict``
                mapping ``clip_cache_key(visual_prompt)`` to a local real-video-clip
                path) to use as a beat's background instead of the drawn icon.

        Returns:
            ``output_path``, once the composed video has been written.

        Raises:
            TypeError: If a required argument is missing or the wrong type.
        """
        beats = kwargs.get("beats")
        output_path = kwargs.get("output_path")
        clip_paths = kwargs.get("clip_paths") or {}
        if not isinstance(beats, list) or not beats or not isinstance(output_path, str):
            raise TypeError("MoviePyTool requires a non-empty list 'beats' and a string 'output_path' argument.")
        if not isinstance(clip_paths, dict):
            raise TypeError("MoviePyTool's 'clip_paths' argument must be a dict if provided.")
        await aiofiles.os.makedirs(str(Path(output_path).parent), exist_ok=True)
        await asyncio.to_thread(self._compose, beats, output_path, clip_paths)
        return output_path

    def _compose(self, beats: list[object], output_path: str, clip_paths: dict[str, str]) -> None:
        """Render the beat clips and write the concatenated video to disk.

        Args:
            beats: Narrated-beat mappings with ``narration``, ``visual_prompt``,
                and ``audio_path`` keys.
            output_path: Destination path for the composed (not yet fast-start) video.
            clip_paths: Maps ``clip_cache_key(visual_prompt)`` to a real-clip path to use
                as that beat's background instead of the drawn icon.
        """
        scenes = []
        try:
            for beat in beats:
                assert isinstance(beat, Mapping)
                clip_path = clip_paths.get(clip_cache_key(str(beat["visual_prompt"])))
                scenes.append(self._compose_scene(beat, clip_path))
            final = concatenate_videoclips(scenes)
            try:
                final.write_videofile(output_path, fps=self._fps, codec="libx264", audio_codec="aac", logger=None)
            finally:
                final.close()
        finally:
            for scene in scenes:
                scene.close()

    def _compose_scene(self, beat: Mapping[str, object], clip_path: str | None) -> CompositeVideoClip:
        """Composite one narrated beat into a background-plus-caption scene clip.

        Args:
            beat: Narrated-beat mapping with ``narration``, ``visual_prompt``,
                and ``audio_path`` keys.
            clip_path: A real Veo clip to use as the background, looped/letterboxed to
                the beat's duration, or ``None`` to fall back to the drawn icon animation.

        Returns:
            One scene clip, its duration and audio track matching the beat's narration.
        """
        audio = AudioFileClip(str(beat["audio_path"]))
        duration = audio.duration
        width, height = self._video_size

        caption = (
            TextClip(
                text=str(beat["narration"]),
                font_size=40,
                color="white",
                size=(width - 120, None),
                method="caption",
            )
            .with_duration(duration)
            .with_position(("center", "bottom"))
        )

        if clip_path is not None:
            background = self._looped_letterboxed_clip(clip_path, duration)
            return CompositeVideoClip([background, caption], size=self._video_size).with_audio(audio)

        visual_prompt = str(beat["visual_prompt"])
        layers: list[VideoClip] = [ColorClip(size=self._video_size, color=(30, 60, 114), duration=duration)]

        icon_size = min(width, height) // 2
        icon_top_left = ((width - icon_size) // 2, height // 6)
        highlight = (
            ImageClip(np.array(icon_library.render_highlight(int(icon_size * 1.6))))
            .with_duration(duration)
            .with_position((icon_top_left[0] - int(icon_size * 0.3), icon_top_left[1] - int(icon_size * 0.3)))
        )
        layers.append(highlight)

        if icon_library.should_show_arrow_overlay(visual_prompt):
            layers.append(ImageClip(np.array(icon_library.render_arrow_overlay(width, height))).with_duration(duration))

        icon_key = icon_library.select_icon_key(visual_prompt)
        icon = (
            ImageClip(np.array(icon_library.render_icon(icon_key, icon_size)))
            .with_duration(duration)
            .resized(lambda t, d=duration: 1 + 0.12 * (t / d))
            .with_position(
                lambda t, x=icon_top_left[0], y=icon_top_left[1], d=duration: (x - 12 * (t / d), y - 8 * (t / d))
            )
        )
        layers.append(icon)
        layers.append(caption)

        return CompositeVideoClip(layers).with_audio(audio)

    def _looped_letterboxed_clip(self, clip_path: str, duration: float) -> VideoClip:
        """Fit a real video clip to the target frame size, looping it to reach ``duration``.

        Args:
            clip_path: Local path to the source clip (Veo footage is often shorter than
                the beat's narration, and rarely exactly ``self._video_size``).
            duration: Target duration in seconds — the beat's narration length.

        Returns:
            A letterboxed clip of exactly ``duration`` seconds, looping the source if needed.
        """
        width, height = self._video_size
        clip = VideoFileClip(clip_path)
        scale = min(width / clip.w, height / clip.h)
        resized = clip.resized(scale).with_position("center")
        if clip.duration < duration:
            looped = resized.with_effects([vfx.Loop(duration=duration)])
        else:
            looped = resized.subclipped(0, duration)
        background = ColorClip(size=self._video_size, color=(0, 0, 0), duration=duration)
        return CompositeVideoClip([background, looped], size=self._video_size)


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
