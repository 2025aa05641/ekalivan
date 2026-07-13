"""LangGraph construction for the video-generation pipeline.

Only the Intake and Pedagogy stages (Curriculum, Lesson Planning, Teacher)
are wired so far. The remaining four agents from the architecture
document's execution chain are added in later sprints, in the same fixed,
linear order.
"""

from langgraph.graph import END
from langgraph.graph.state import CompiledStateGraph, StateGraph

from app.core.interfaces import ILlmProvider, IMcpTool
from app.features.video_generator.agents import CurriculumAgent, LessonPlanningAgent, ParserAgent, TeacherAgent
from app.features.video_generator.models import VideoGenerationState
from app.features.video_generator.skills.curriculum import CurriculumSkill
from app.features.video_generator.skills.lesson_planning import LessonPlanningSkill
from app.features.video_generator.skills.teacher import TeacherSkill


def build_video_generation_graph(
    parser_tool: IMcpTool, llm_provider: ILlmProvider
) -> CompiledStateGraph[VideoGenerationState]:
    """Compile the linear video-generation graph.

    Args:
        parser_tool: MCP tool used by the Parser agent to read the source document.
        llm_provider: LLM provider shared by the Pedagogy-stage agents' skills.

    Returns:
        A compiled graph that parses the source file to Markdown, structures it
        into concept sections, paces those sections for a Class 6 lesson, and
        rewrites them into localized narration.
    """
    graph: StateGraph[VideoGenerationState] = StateGraph(VideoGenerationState)
    graph.add_node("parser", ParserAgent(parser_tool))
    graph.add_node("curriculum", CurriculumAgent(CurriculumSkill(llm_provider)))
    graph.add_node("lesson_planning", LessonPlanningAgent(LessonPlanningSkill(llm_provider)))
    graph.add_node("teacher", TeacherAgent(TeacherSkill(llm_provider)))
    graph.set_entry_point("parser")
    graph.add_edge("parser", "curriculum")
    graph.add_edge("curriculum", "lesson_planning")
    graph.add_edge("lesson_planning", "teacher")
    graph.add_edge("teacher", END)
    return graph.compile()
