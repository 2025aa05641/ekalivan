"""LangGraph agent nodes for the video-generation pipeline."""

from app.core.interfaces import IMcpTool
from app.features.video_generator.models import VideoGenerationState


class ParserAgent:
    """Intake-stage agent: converts the source chapter file to Markdown."""

    def __init__(self, parser_tool: IMcpTool) -> None:
        """Create the agent with its injected MCP parser tool.

        Args:
            parser_tool: Tool that converts a document path to Markdown text.
        """
        self._parser_tool = parser_tool

    async def __call__(self, state: VideoGenerationState) -> dict[str, str]:
        """Populate ``markdown_content`` from the state's source file path.

        Args:
            state: Current shared pipeline state.

        Returns:
            Partial state update containing the parsed Markdown content.

        Raises:
            ValueError: If the parser tool returns empty or non-text content.
        """
        markdown_content = await self._parser_tool.execute(file_path=state.file_path)
        if not isinstance(markdown_content, str) or not markdown_content.strip():
            raise ValueError(f"Parser produced no content for '{state.file_path}'.")
        return {"markdown_content": markdown_content}
