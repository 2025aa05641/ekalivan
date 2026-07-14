"""StorageTool adapter tests."""

import json
from pathlib import Path

import pytest

from app.infrastructure.storage import StorageTool


async def test_write_text_creates_parent_dirs_and_writes_content(tmp_path: Path) -> None:
    """The tool creates missing parent directories and writes the given text."""
    tool = StorageTool()
    path = tmp_path / "nested" / "manifest.json"
    content = json.dumps({"task_id": "job-1"})

    result = await tool.execute(operation="write_text", path=str(path), content=content)

    assert result == str(path)
    assert path.read_text(encoding="utf-8") == content


async def test_file_size_returns_bytes_for_an_existing_file(tmp_path: Path) -> None:
    """The tool reports the real size of a file that exists."""
    path = tmp_path / "video.mp4"
    path.write_bytes(b"0123456789")
    tool = StorageTool()

    result = await tool.execute(operation="file_size", path=str(path))

    assert result == 10


async def test_file_size_returns_none_for_a_missing_file(tmp_path: Path) -> None:
    """The tool reports no size for a file that does not exist."""
    tool = StorageTool()

    result = await tool.execute(operation="file_size", path=str(tmp_path / "does_not_exist.mp4"))

    assert result is None


async def test_execute_requires_string_path() -> None:
    """The tool rejects a missing or non-string 'path' argument."""
    tool = StorageTool()

    with pytest.raises(TypeError):
        await tool.execute(operation="file_size")


async def test_write_text_requires_string_content(tmp_path: Path) -> None:
    """The tool rejects a missing or non-string 'content' argument."""
    tool = StorageTool()

    with pytest.raises(TypeError):
        await tool.execute(operation="write_text", path=str(tmp_path / "out.txt"))


async def test_execute_rejects_unrecognized_operation(tmp_path: Path) -> None:
    """The tool rejects an unsupported 'operation' value."""
    tool = StorageTool()

    with pytest.raises(ValueError, match="Unsupported StorageTool operation"):
        await tool.execute(operation="delete", path=str(tmp_path / "out.txt"))
