"""PublishingSkill: validates the rendered video and registers it in the cache manifest."""

import json
from datetime import datetime, timezone
from pathlib import Path

from app.core.interfaces import IMcpTool


class PublishingSkill:
    """Facade that validates the final video and writes its cache-manifest entry.

    The architecture document also assigns this stage responsibility for closing the
    SSE stream. The API currently exposes status through polling, not SSE, so that
    part of the responsibility does not apply yet.
    """

    def __init__(self, storage_tool: IMcpTool, static_assets_dir: Path) -> None:
        """Create the skill with its injected storage tool and static-assets root.

        Args:
            storage_tool: MCP tool used to check the rendered file and write the manifest.
            static_assets_dir: Directory ``output_video_path`` is served from, used to
                derive the public ``video_url``.
        """
        self._storage_tool = storage_tool
        self._static_assets_dir = static_assets_dir

    async def publish(self, output_video_path: str, task_id: str) -> str:
        """Validate the rendered video exists and write its manifest entry.

        Args:
            output_video_path: Path to the final video produced by the Video Rendering stage.
            task_id: Owning job's identifier.

        Returns:
            The public URL the video is servable at.

        Raises:
            ValueError: If the rendered video is missing or empty.
        """
        file_size = await self._storage_tool.execute(operation="file_size", path=output_video_path)
        if not isinstance(file_size, int) or file_size <= 0:
            raise ValueError(f"Rendered video at '{output_video_path}' is missing or empty.")

        video_url = "/static/" + Path(output_video_path).relative_to(self._static_assets_dir).as_posix()
        manifest = {
            "task_id": task_id,
            "output_video_path": output_video_path,
            "video_url": video_url,
            "file_size_bytes": file_size,
            "published_at": datetime.now(timezone.utc).isoformat(),
        }
        manifest_path = Path(output_video_path).parent / "manifest.json"
        await self._storage_tool.execute(
            operation="write_text", path=str(manifest_path), content=json.dumps(manifest, indent=2)
        )
        return video_url
