"""MCP tool adapters wrapping external document and media binaries."""

import asyncio

from markitdown import MarkItDown

from app.core.interfaces import IMcpTool


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
