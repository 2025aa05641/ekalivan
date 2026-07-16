"""Skills layer tests."""

import json
from pathlib import Path

from app.core.interfaces import IMcpTool
from app.features.video_generator.models import ChapterSection, NarratedBeat, ScriptBeat, WordTimestamp
from app.features.video_generator.skills.curriculum import CurriculumSkill
from app.features.video_generator.skills.lesson_planning import LessonPlanningSkill
from app.features.video_generator.skills.narration import NarrationSkill
from app.features.video_generator.skills.publishing import PublishingSkill
from app.features.video_generator.skills.rendering import RenderingSkill, clip_cache_key
from app.features.video_generator.skills.storyboard import StoryboardSkill
from app.features.video_generator.skills.teacher import TeacherSkill
from tests.conftest import FakeCompositionTool, FakeEncodeTool, FakeLlmProvider, FakeStorageTool, FakeTtsTool


async def test_structure_chapter_returns_sections_from_provider() -> None:
    """CurriculumSkill maps the provider's validated response onto ChapterSection objects."""
    provider = FakeLlmProvider()
    skill = CurriculumSkill(provider)

    sections = await skill.structure_chapter("# The World of Plants\n\nPlants make food using sunlight.")

    assert sections == [ChapterSection(title="Mock Section", content="Mock content.")]
    assert provider.last_prompt is not None
    assert "Plants make food using sunlight." in provider.last_prompt


async def test_apply_pacing_returns_sections_from_provider() -> None:
    """LessonPlanningSkill sends the input sections and returns the provider's response."""
    provider = FakeLlmProvider()
    skill = LessonPlanningSkill(provider)
    raw_sections = [ChapterSection(title="Photosynthesis", content="Plants make food using sunlight.")]

    sections = await skill.apply_pacing(raw_sections)

    assert sections == [ChapterSection(title="Mock Section", content="Mock content.")]
    assert provider.last_prompt is not None
    assert "Plants make food using sunlight." in provider.last_prompt


async def test_localize_sections_returns_sections_from_provider() -> None:
    """TeacherSkill sends the input sections and returns the provider's response."""
    provider = FakeLlmProvider()
    skill = TeacherSkill(provider)
    raw_sections = [ChapterSection(title="Photosynthesis", content="Plants make food using sunlight.")]

    sections = await skill.localize_sections(raw_sections)

    assert sections == [ChapterSection(title="Mock Section", content="Mock content.")]
    assert provider.last_prompt is not None
    assert "Plants make food using sunlight." in provider.last_prompt


async def test_create_storyboard_returns_beats_from_provider() -> None:
    """StoryboardSkill sends the input sections and returns the provider's beats response."""
    provider = FakeLlmProvider()
    skill = StoryboardSkill(provider)
    raw_sections = [ChapterSection(title="Photosynthesis", content="Plants make food using sunlight.")]

    beats = await skill.create_storyboard(raw_sections)

    assert beats == [ScriptBeat(narration="Mock narration.", visual_prompt="Mock visual.", duration_seconds=5.0)]
    assert provider.last_prompt is not None
    assert "Plants make food using sunlight." in provider.last_prompt


async def test_narrate_beat_returns_narrated_beat_from_tool(tmp_path: Path) -> None:
    """NarrationSkill builds a per-job, per-beat output path and attaches word timing."""
    skill = NarrationSkill(FakeTtsTool(), tmp_path)
    beat = ScriptBeat(narration="Plants make food.", visual_prompt="A sunlit leaf.", duration_seconds=4.0)

    narrated_beat = await skill.narrate_beat(beat, beat_index=2, task_id="job-42")

    assert narrated_beat == NarratedBeat(
        narration="Plants make food.",
        visual_prompt="A sunlit leaf.",
        duration_seconds=4.0,
        audio_path=str(tmp_path / "job-42" / "beat_002.mp3"),
        word_timestamps=[
            WordTimestamp(
                word="Mock",
                start_seconds=0.0,
                end_seconds=0.5,
            ),
        ],
    )


async def test_render_video_returns_final_path_from_encode_tool(tmp_path: Path) -> None:
    """RenderingSkill runs composition then encode and returns the final video path."""
    skill = RenderingSkill(FakeCompositionTool(), FakeEncodeTool(), tmp_path)
    narrated_beat = NarratedBeat(
        narration="Plants make food.", visual_prompt="A sunlit leaf.", duration_seconds=4.0, audio_path="beat.mp3"
    )

    output_video_path = await skill.render_video([narrated_beat], task_id="job-42")

    assert output_video_path == str(tmp_path / "job-42" / "final.mp4")


async def test_render_video_writes_beats_manifest_for_clip_generation(tmp_path: Path) -> None:
    """RenderingSkill writes a beats.json manifest with a stable, prompt-derived clip id."""
    skill = RenderingSkill(FakeCompositionTool(), FakeEncodeTool(), tmp_path)
    narrated_beat = NarratedBeat(
        narration="Plants make food.", visual_prompt="A sunlit leaf.", duration_seconds=4.0, audio_path="beat.mp3"
    )

    await skill.render_video([narrated_beat], task_id="job-42")

    manifest = json.loads((tmp_path / "job-42" / "beats.json").read_text(encoding="utf-8"))
    assert manifest == [
        {
            "id": clip_cache_key("A sunlit leaf."),
            "prompt": "A sunlit leaf.",
            "narration": "Plants make food.",
            "duration_seconds": 4.0,
            "frames": 61,
        }
    ]


async def test_render_video_passes_empty_clip_paths_when_no_veo_tool_configured(tmp_path: Path) -> None:
    """RenderingSkill still calls the composition tool with an (empty) 'clip_paths' when Veo is unset."""

    class _RecordingCompositionTool(IMcpTool):
        def __init__(self) -> None:
            self.last_kwargs: dict[str, object] = {}

        async def execute(self, **kwargs: object) -> object:
            self.last_kwargs = kwargs
            return kwargs["output_path"]

    composition_tool = _RecordingCompositionTool()
    skill = RenderingSkill(composition_tool, FakeEncodeTool(), tmp_path)
    narrated_beat = NarratedBeat(
        narration="Plants make food.", visual_prompt="A sunlit leaf.", duration_seconds=4.0, audio_path="beat.mp3"
    )

    await skill.render_video([narrated_beat], task_id="job-42")

    assert composition_tool.last_kwargs["clip_paths"] == {}


async def test_render_video_forwards_veo_clip_paths_to_composition_tool(tmp_path: Path) -> None:
    """RenderingSkill runs the Veo tool first and passes its clip paths on to composition."""

    class _FakeVeoTool(IMcpTool):
        def __init__(self) -> None:
            self.last_kwargs: dict[str, object] = {}

        async def execute(self, **kwargs: object) -> object:
            self.last_kwargs = kwargs
            beats = kwargs["beats"]
            assert isinstance(beats, list)
            return {beat["id"]: f"/cache/{beat['id']}.mp4" for beat in beats}

    class _RecordingCompositionTool(IMcpTool):
        def __init__(self) -> None:
            self.last_kwargs: dict[str, object] = {}

        async def execute(self, **kwargs: object) -> object:
            self.last_kwargs = kwargs
            return kwargs["output_path"]

    veo_tool = _FakeVeoTool()
    composition_tool = _RecordingCompositionTool()
    skill = RenderingSkill(composition_tool, FakeEncodeTool(), tmp_path, veo_tool)
    narrated_beat = NarratedBeat(
        narration="Plants make food.", visual_prompt="A sunlit leaf.", duration_seconds=4.0, audio_path="beat.mp3"
    )

    await skill.render_video([narrated_beat], task_id="job-42")

    beat_id = clip_cache_key("A sunlit leaf.")
    assert veo_tool.last_kwargs["beats"] == [
        {"id": beat_id, "visual_prompt": "A sunlit leaf.", "duration_seconds": 4.0}
    ]
    assert veo_tool.last_kwargs["cache_dir"] == str(tmp_path / "job-42" / "veo_clips")
    assert composition_tool.last_kwargs["clip_paths"] == {beat_id: f"/cache/{beat_id}.mp4"}


async def test_publish_returns_video_url_relative_to_static_assets_dir(tmp_path: Path) -> None:
    """PublishingSkill derives the public URL from the video path and the static-assets root."""
    skill = PublishingSkill(FakeStorageTool(), tmp_path)
    output_video_path = str(tmp_path / "video" / "job-42" / "final.mp4")

    video_url = await skill.publish(output_video_path, task_id="job-42")

    assert video_url == "/static/video/job-42/final.mp4"
