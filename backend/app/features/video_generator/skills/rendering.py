"""RenderingSkill: coordinates track placement for MoviePy and the final FFmpeg encode."""

from pathlib import Path

from app.core.interfaces import IMcpTool
from app.features.video_generator.models import NarratedBeat


class RenderingSkill:
    """Facade that composites narrated beats into one streaming-ready MP4."""

    def __init__(self, composition_tool: IMcpTool, encode_tool: IMcpTool, base_output_dir: Path) -> None:
        """Create the skill with its injected composition and encode tools.

        Args:
            composition_tool: MCP tool that composites beats into one video (MoviePy).
            encode_tool: MCP tool that re-encodes the composed video for streaming (FFmpeg).
            base_output_dir: Directory under which per-job rendered video files are written.
        """
        self._composition_tool = composition_tool
        self._encode_tool = encode_tool
        self._base_output_dir = base_output_dir

    async def render_video(self, narrated_beats: list[NarratedBeat], task_id: str) -> str:
        """Composite narrated beats and produce the final fast-start video.

        Args:
            narrated_beats: Beats with synthesized audio, produced by the Narration stage.
            task_id: Owning job's identifier, used to keep output files from concurrent jobs apart.

        Returns:
            Path to the final, streaming-ready video file.

        Raises:
            ValueError: If the encode tool does not return the final video path.
        """
        job_dir = self._base_output_dir / task_id
        composed_path = job_dir / "composed.mp4"
        final_path = job_dir / "final.mp4"
        await self._composition_tool.execute(
            beats=[beat.model_dump() for beat in narrated_beats], output_path=str(composed_path)
        )
        result = await self._encode_tool.execute(input_path=str(composed_path), output_path=str(final_path))
        if not isinstance(result, str):
            raise ValueError("Encode tool did not return the final video path.")
        return result
