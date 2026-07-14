"""StorageTool: non-blocking disk reads, writes, and existence checks via aiofiles."""

from pathlib import Path

import aiofiles
import aiofiles.os

from app.core.interfaces import IMcpTool


class StorageTool(IMcpTool):
    """Wraps aiofiles behind the single async ``IMcpTool`` contract."""

    async def execute(self, **kwargs: object) -> object:
        """Dispatch a disk operation selected by ``operation``.

        Args:
            kwargs: Must contain ``operation`` (``"write_text"`` or ``"file_size"``)
                and ``path`` (``str``). ``"write_text"`` also requires ``content`` (``str``).

        Returns:
            ``path`` for ``"write_text"``; the file size in bytes, or ``None`` if the
            file does not exist, for ``"file_size"``.

        Raises:
            TypeError: If a required argument is missing or the wrong type.
            ValueError: If ``operation`` is not recognized.
        """
        operation = kwargs.get("operation")
        path = kwargs.get("path")
        if not isinstance(path, str):
            raise TypeError("StorageTool requires a string 'path' argument.")
        if operation == "write_text":
            return await self._write_text(path, kwargs.get("content"))
        if operation == "file_size":
            return await self._file_size(path)
        raise ValueError(f"Unsupported StorageTool operation: '{operation}'.")

    async def _write_text(self, path: str, content: object) -> str:
        """Write ``content`` to ``path``, creating parent directories as needed.

        Args:
            path: Destination file path.
            content: Text content to write.

        Returns:
            ``path``, once the write has completed.

        Raises:
            TypeError: If ``content`` is not a string.
        """
        if not isinstance(content, str):
            raise TypeError("StorageTool 'write_text' requires a string 'content' argument.")
        await aiofiles.os.makedirs(str(Path(path).parent), exist_ok=True)
        async with aiofiles.open(path, "w", encoding="utf-8") as file:
            await file.write(content)
        return path

    async def _file_size(self, path: str) -> int | None:
        """Return the size of the file at ``path`` in bytes, or ``None`` if it is missing.

        Args:
            path: File path to inspect.

        Returns:
            File size in bytes, or ``None`` if the file does not exist.
        """
        if not await aiofiles.os.path.exists(path):
            return None
        stat_result = await aiofiles.os.stat(path)
        return stat_result.st_size
