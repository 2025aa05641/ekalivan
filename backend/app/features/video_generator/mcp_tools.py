"""MCP tool adapters wrapping external document and media binaries."""

import asyncio
from collections.abc import AsyncIterator, Callable, Mapping
from pathlib import Path
from typing import Protocol, cast

import aiofiles
import aiofiles.os
import edge_tts
from markitdown import MarkItDown

from app.core.interfaces import IMcpTool
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

    def __init__(self, communicate_factory: CommunicateFactory | None = None) -> None:
        """Create the tool with an injectable Edge TTS communicate-session factory.

        Args:
            communicate_factory: Builds the streaming session for a given text/voice.
                Defaults to a real ``edge_tts.Communicate`` session.
        """
        self._communicate_factory = communicate_factory or _default_communicate_factory

    async def execute(self, **kwargs: object) -> object:
        """Synthesize ``text`` to ``output_path`` and return its word timestamps.

        Args:
            kwargs: Must contain ``text``, ``voice``, and ``output_path`` (all ``str``).

        Returns:
            Word-level timestamps captured during synthesis.

        Raises:
            TypeError: If a required argument is missing or not a string.
            ValueError: If synthesis produced no word timestamps.
        """
        text = kwargs.get("text")
        voice = kwargs.get("voice")
        output_path = kwargs.get("output_path")
        if not isinstance(text, str) or not isinstance(voice, str) or not isinstance(output_path, str):
            raise TypeError("EdgeTtsTool requires string 'text', 'voice', and 'output_path' arguments.")

        await aiofiles.os.makedirs(str(Path(output_path).parent), exist_ok=True)
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
