"""LangGraph construction for the video-generation pipeline.

Only the Intake, Pedagogy (Curriculum, Lesson Planning, Teacher),
Storyboarding, and Audio & Sync (Narration) stages are wired so far. The
remaining two agents from the architecture document's execution chain
are added in later sprints, in the same fixed, linear order.
"""

from pathlib import Path

from langgraph.graph import END
from langgraph.graph.state import CompiledStateGraph, StateGraph

from app.core.interfaces import ILlmProvider, IMcpTool
from app.features.video_generator.agents import (
    CurriculumAgent,
    LessonPlanningAgent,
    NarrationAgent,
    ParserAgent,
    StoryboardAgent,
    TeacherAgent,
)
from app.features.video_generator.models import VideoGenerationState
from app.features.video_generator.skills.curriculum import CurriculumSkill
from app.features.video_generator.skills.lesson_planning import LessonPlanningSkill
from app.features.video_generator.skills.narration import NarrationSkill
from app.features.video_generator.skills.storyboard import StoryboardSkill
from app.features.video_generator.skills.teacher import TeacherSkill


def build_video_generation_graph(
    parser_tool: IMcpTool,
    llm_provider: ILlmProvider,
    tts_tool: IMcpTool,
    narration_output_dir: Path,
) -> CompiledStateGraph[VideoGenerationState]:
    """Compile the linear video-generation graph.

    Args:
        parser_tool: MCP tool used by the Parser agent to read the source document.
        llm_provider: LLM provider shared by the Pedagogy- and Storyboarding-stage skills.
        tts_tool: MCP tool used by the Narration agent to synthesize speech.
        narration_output_dir: Base directory under which per-job narration audio is written.

    Returns:
        A compiled graph that parses the source file to Markdown, structures it into
        concept sections, paces and localizes those sections for a Class 6 lesson, turns
        them into timed storyboard beats, and synthesizes narration audio and word timing
        for each beat.
    """
    graph: StateGraph[VideoGenerationState] = StateGraph(VideoGenerationState)
    graph.add_node("parser", ParserAgent(parser_tool))
    graph.add_node("curriculum", CurriculumAgent(CurriculumSkill(llm_provider)))
    graph.add_node("lesson_planning", LessonPlanningAgent(LessonPlanningSkill(llm_provider)))
    graph.add_node("teacher", TeacherAgent(TeacherSkill(llm_provider)))
    graph.add_node("storyboard", StoryboardAgent(StoryboardSkill(llm_provider)))
    graph.add_node("narration", NarrationAgent(NarrationSkill(tts_tool, narration_output_dir)))
    graph.set_entry_point("parser")
    graph.add_edge("parser", "curriculum")
    graph.add_edge("curriculum", "lesson_planning")
    graph.add_edge("lesson_planning", "teacher")
    graph.add_edge("teacher", "storyboard")
    graph.add_edge("storyboard", "narration")
    graph.add_edge("narration", END)
    return graph.compile()
