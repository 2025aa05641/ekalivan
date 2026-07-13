"""Video-generation graph construction and invocation tests."""

from app.core.interfaces import IMcpTool
from app.features.video_generator.graph import build_video_generation_graph
from app.features.video_generator.models import VideoGenerationState


class _StubParserTool(IMcpTool):
    """Deterministic MCP tool stub for graph-level tests."""

    async def execute(self, **kwargs: object) -> object:
        return f"# Parsed: {kwargs['file_path']}"


async def test_graph_invocation_populates_markdown_content() -> None:
    """Invoking the compiled graph runs the Parser agent and returns Markdown content."""
    graph = build_video_generation_graph(_StubParserTool())

    raw_result = await graph.ainvoke(VideoGenerationState(file_path="chapter.pdf"))
    result = VideoGenerationState.model_validate(raw_result)

    assert result.markdown_content == "# Parsed: chapter.pdf"
