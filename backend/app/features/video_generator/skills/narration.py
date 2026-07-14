"""NarrationSkill: drives TTS synthesis and validates per-beat timing output."""

from pathlib import Path

from app.core.interfaces import IMcpTool
from app.features.video_generator.models import NarratedBeat, ScriptBeat, WordTimestamp

DEFAULT_VOICE = "en-US-AriaNeural"


class NarrationSkill:
    """Facade that synthesizes narration audio and validates word-level timing per beat."""

    def __init__(self, tts_tool: IMcpTool, base_output_dir: Path, voice: str = DEFAULT_VOICE) -> None:
        """Create the skill with its injected TTS tool and output configuration.

        Args:
            tts_tool: MCP tool that synthesizes speech and captures word timestamps.
            base_output_dir: Directory under which per-job audio subfolders are created.
            voice: Edge TTS voice used for narration.
        """
        self._tts_tool = tts_tool
        self._base_output_dir = base_output_dir
        self._voice = voice

    async def narrate_beat(self, beat: ScriptBeat, beat_index: int, task_id: str) -> NarratedBeat:
        """Synthesize one storyboard beat's narration and attach its word timing.

        Args:
            beat: Storyboard beat to narrate.
            beat_index: Position of this beat within the storyboard, used for a stable filename.
            task_id: Owning job's identifier, used to keep beats from concurrent jobs apart.

        Returns:
            The beat enriched with its synthesized audio path and word timestamps.

        Raises:
            ValueError: If the TTS tool does not return word-level timestamps.
        """
        output_path = self._base_output_dir / task_id / f"beat_{beat_index:03d}.mp3"
        result = await self._tts_tool.execute(text=beat.narration, voice=self._voice, output_path=str(output_path))
        if not isinstance(result, list) or not all(isinstance(item, WordTimestamp) for item in result):
            raise ValueError("Narration tool did not return word-level timestamps.")
        return NarratedBeat(
            narration=beat.narration,
            visual_prompt=beat.visual_prompt,
            duration_seconds=beat.duration_seconds,
            audio_path=str(output_path),
            word_timestamps=result,
        )
