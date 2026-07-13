"""LangGraph construction for the video-generation pipeline.

Only the Intake stage (``ParserAgent``) is wired so far. The remaining
seven agents from the architecture document's execution chain are added
in later sprints, in the same fixed, linear order.
"""

from langgraph.graph import END
from langgraph.graph.state import CompiledStateGraph, StateGraph

from app.core.interfaces import IMcpTool
from app.features.video_generator.agents import ParserAgent
from app.features.video_generator.models import VideoGenerationState


def build_video_generation_graph(parser_tool: IMcpTool) -> CompiledStateGraph[VideoGenerationState]:
    """Compile the linear video-generation graph.

    Args:
        parser_tool: MCP tool used by the Parser agent to read the source document.

    Returns:
        A compiled graph whose single node parses the source file to Markdown.
    """
    graph: StateGraph[VideoGenerationState] = StateGraph(VideoGenerationState)
    graph.add_node("parser", ParserAgent(parser_tool))
    graph.set_entry_point("parser")
    graph.add_edge("parser", END)
    return graph.compile()
