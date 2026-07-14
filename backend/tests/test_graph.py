"""Video-generation graph construction and invocation tests."""

from pathlib import Path

from app.core.interfaces import IMcpTool
from app.features.video_generator.graph import build_video_generation_graph
from app.features.video_generator.models import VideoGenerationState
from tests.conftest import FakeCompositionTool, FakeEncodeTool, FakeLlmProvider, FakeTtsTool


class _StubParserTool(IMcpTool):
    """Deterministic MCP tool stub for graph-level tests."""

    async def execute(self, **kwargs: object) -> object:
        return f"# Parsed: {kwargs['file_path']}"


async def test_graph_invocation_runs_full_wired_chain(tmp_path: Path) -> None:
    """Invoking the compiled graph runs every wired agent, Parser through Video Rendering, in order."""
    graph = build_video_generation_graph(
        _StubParserTool(),
        FakeLlmProvider(),
        FakeTtsTool(),
        tmp_path / "audio",
        FakeCompositionTool(),
        FakeEncodeTool(),
        tmp_path / "video",
    )

    raw_result = await graph.ainvoke(VideoGenerationState(file_path="chapter.pdf", task_id="job-1"))
    result = VideoGenerationState.model_validate(raw_result)

    assert result.markdown_content == "# Parsed: chapter.pdf"
    assert result.sections[0].title == "Mock Section"
    assert result.storyboard_beats[0].narration == "Mock narration."
    assert result.narrated_beats[0].word_timestamps[0].word == "Mock"
    assert result.output_video_path == str(tmp_path / "video" / "job-1" / "final.mp4")
