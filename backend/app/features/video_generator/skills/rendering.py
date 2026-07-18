"""RenderingSkill: coordinates track placement for MoviePy and the final FFmpeg encode."""

import hashlib
import json
from pathlib import Path

import aiofiles
import aiofiles.os

from app.core.interfaces import IMcpTool
from app.features.video_generator.models import NarratedBeat

# Matches the Wan2.1-T2V worker notebook's defaults (Textbook-to-Video_Output/), so a
# beats.json exported here can be fed straight into that notebook without editing it.
_WAN_FPS = 16
_MIN_WAN_FRAMES = 9
_MAX_WAN_FRAMES = 81


def clip_cache_key(visual_prompt: str) -> str:
    """Derive the stable clip-cache filename stem for a beat's visual prompt.

    Shared with the Wan2.1 clip-generation notebook so a beat here and the clip it
    generates there always agree on a name, without either side needing beat IDs.

    Args:
        visual_prompt: The beat's ``visual_prompt`` text.

    Returns:
        A short, filesystem-safe, content-derived identifier.
    """
    return hashlib.sha1(visual_prompt.encode("utf-8")).hexdigest()[:12]


def _wan_frame_count(duration_seconds: float) -> int:
    """Round a beat duration to a Wan2.1-compatible frame count (``4n + 1``, clamped).

    Args:
        duration_seconds: The beat's narration-driven duration.

    Returns:
        A frame count Wan2.1 accepts, clamped to a sane clip-length range.
    """
    raw = round(duration_seconds * _WAN_FPS)
    rounded = max(1, (raw - 1) // 4 * 4 + 1)
    return min(_MAX_WAN_FRAMES, max(_MIN_WAN_FRAMES, rounded))


class RenderingSkill:
    """Facade that composites narrated beats into one streaming-ready MP4."""

    def __init__(
        self,
        composition_tool: IMcpTool,
        encode_tool: IMcpTool,
        base_output_dir: Path,
        clip_tool: IMcpTool | None = None,
    ) -> None:
        """Create the skill with its injected composition and encode tools.

        Args:
            composition_tool: MCP tool that composites beats into one video (MoviePy).
            encode_tool: MCP tool that re-encodes the composed video for streaming (FFmpeg).
            base_output_dir: Directory under which per-job rendered video files are written.
            clip_tool: Optional MCP tool that supplies real video clips per beat (Veo or
                Kaggle, per ``VIDEO_CLIP_PROVIDER``). When omitted, every beat falls back
                to the composition tool's local animation — rendering never depends on an
                external clip source being configured.
        """
        self._composition_tool = composition_tool
        self._encode_tool = encode_tool
        self._base_output_dir = base_output_dir
        self._clip_tool = clip_tool

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
        await self._write_beats_manifest(narrated_beats, job_dir)

        clip_paths: object = {}
        if self._clip_tool is not None:
            clip_beats = [
                {"id": clip_cache_key(beat.visual_prompt), "visual_prompt": beat.visual_prompt,
                 "duration_seconds": beat.duration_seconds}
                for beat in narrated_beats
            ]
            clip_paths = await self._clip_tool.execute(beats=clip_beats, cache_dir=str(job_dir / "veo_clips"))

        await self._composition_tool.execute(
            beats=[beat.model_dump() for beat in narrated_beats],
            clip_paths=clip_paths,
            output_path=str(composed_path),
        )
        result = await self._encode_tool.execute(input_path=str(composed_path), output_path=str(final_path))
        if not isinstance(result, str):
            raise ValueError("Encode tool did not return the final video path.")
        return result

    async def _write_beats_manifest(self, narrated_beats: list[NarratedBeat], job_dir: Path) -> None:
        """Write ``beats.json`` alongside the rendered video for external clip generation.

        Captures each beat's ``visual_prompt`` under its stable ``clip_cache_key`` so this
        job's content can be handed to the Wan2.1 Kaggle notebook to generate real video
        clips, without re-deriving prompts by hand.

        Args:
            narrated_beats: Beats with synthesized audio, produced by the Narration stage.
            job_dir: This job's output directory (created if missing).
        """
        manifest = [
            {
                "id": clip_cache_key(beat.visual_prompt),
                "prompt": beat.visual_prompt,
                "narration": beat.narration,
                "duration_seconds": beat.duration_seconds,
                "frames": _wan_frame_count(beat.duration_seconds),
            }
            for beat in narrated_beats
        ]
        await aiofiles.os.makedirs(str(job_dir), exist_ok=True)
        async with aiofiles.open(job_dir / "beats.json", "w", encoding="utf-8") as manifest_file:
            await manifest_file.write(json.dumps(manifest, indent=2, ensure_ascii=False))
