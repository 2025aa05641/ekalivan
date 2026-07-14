"""LangGraph construction for the video-generation pipeline.

Only the Intake, Pedagogy (Curriculum, Lesson Planning, Teacher),
Storyboarding, Audio & Sync (Narration), and Assembly (Video Rendering)
stages are wired so far. Publishing, the final agent from the
architecture document's execution chain, is added in a later sprint.
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
    VideoRenderingAgent,
)
from app.features.video_generator.models import VideoGenerationState
from app.features.video_generator.skills.curriculum import CurriculumSkill
from app.features.video_generator.skills.lesson_planning import LessonPlanningSkill
from app.features.video_generator.skills.narration import NarrationSkill
from app.features.video_generator.skills.rendering import RenderingSkill
from app.features.video_generator.skills.storyboard import StoryboardSkill
from app.features.video_generator.skills.teacher import TeacherSkill


def build_video_generation_graph(
    parser_tool: IMcpTool,
    llm_provider: ILlmProvider,
    tts_tool: IMcpTool,
    narration_output_dir: Path,
    composition_tool: IMcpTool,
    encode_tool: IMcpTool,
    rendering_output_dir: Path,
) -> CompiledStateGraph[VideoGenerationState]:
    """Compile the linear video-generation graph.

    Args:
        parser_tool: MCP tool used by the Parser agent to read the source document.
        llm_provider: LLM provider shared by the Pedagogy- and Storyboarding-stage skills.
        tts_tool: MCP tool used by the Narration agent to synthesize speech.
        narration_output_dir: Base directory under which per-job narration audio is written.
        composition_tool: MCP tool used by the Video Rendering agent to composite beats (MoviePy).
        encode_tool: MCP tool used by the Video Rendering agent for the final encode (FFmpeg).
        rendering_output_dir: Base directory under which per-job rendered video files are written.

    Returns:
        A compiled graph that parses the source file to Markdown, structures it into
        concept sections, paces and localizes those sections for a Class 6 lesson, turns
        them into timed storyboard beats, synthesizes narration audio and word timing for
        each beat, and composites the result into one streaming-ready video.
    """
    graph: StateGraph[VideoGenerationState] = StateGraph(VideoGenerationState)
    graph.add_node("parser", ParserAgent(parser_tool))
    graph.add_node("curriculum", CurriculumAgent(CurriculumSkill(llm_provider)))
    graph.add_node("lesson_planning", LessonPlanningAgent(LessonPlanningSkill(llm_provider)))
    graph.add_node("teacher", TeacherAgent(TeacherSkill(llm_provider)))
    graph.add_node("storyboard", StoryboardAgent(StoryboardSkill(llm_provider)))
    graph.add_node("narration", NarrationAgent(NarrationSkill(tts_tool, narration_output_dir)))
    graph.add_node(
        "video_rendering",
        VideoRenderingAgent(RenderingSkill(composition_tool, encode_tool, rendering_output_dir)),
    )
    graph.set_entry_point("parser")
    graph.add_edge("parser", "curriculum")
    graph.add_edge("curriculum", "lesson_planning")
    graph.add_edge("lesson_planning", "teacher")
    graph.add_edge("teacher", "storyboard")
    graph.add_edge("storyboard", "narration")
    graph.add_edge("narration", "video_rendering")
    graph.add_edge("video_rendering", END)
    return graph.compile()
