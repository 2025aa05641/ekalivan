"""LangGraph construction for the video-generation pipeline.

Only the Intake and Curriculum stages are wired so far. The remaining six
agents from the architecture document's execution chain are added in later
sprints, in the same fixed, linear order.
"""

from langgraph.graph import END
from langgraph.graph.state import CompiledStateGraph, StateGraph

from app.core.interfaces import ILlmProvider, IMcpTool
from app.features.video_generator.agents import CurriculumAgent, ParserAgent
from app.features.video_generator.models import VideoGenerationState
from app.features.video_generator.skills.curriculum import CurriculumSkill


def build_video_generation_graph(
    parser_tool: IMcpTool, llm_provider: ILlmProvider
) -> CompiledStateGraph[VideoGenerationState]:
    """Compile the linear video-generation graph.

    Args:
        parser_tool: MCP tool used by the Parser agent to read the source document.
        llm_provider: LLM provider used by the Curriculum agent's skill.

    Returns:
        A compiled graph that parses the source file to Markdown, then structures
        it into concept sections.
    """
    graph: StateGraph[VideoGenerationState] = StateGraph(VideoGenerationState)
    graph.add_node("parser", ParserAgent(parser_tool))
    graph.add_node("curriculum", CurriculumAgent(CurriculumSkill(llm_provider)))
    graph.set_entry_point("parser")
    graph.add_edge("parser", "curriculum")
    graph.add_edge("curriculum", END)
    return graph.compile()
