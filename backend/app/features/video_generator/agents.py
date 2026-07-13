"""LangGraph agent nodes for the video-generation pipeline."""

from app.core.interfaces import IMcpTool
from app.features.video_generator.models import ChapterSection, ScriptBeat, VideoGenerationState
from app.features.video_generator.skills.curriculum import CurriculumSkill
from app.features.video_generator.skills.lesson_planning import LessonPlanningSkill
from app.features.video_generator.skills.storyboard import StoryboardSkill
from app.features.video_generator.skills.teacher import TeacherSkill


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


class CurriculumAgent:
    """Pedagogy-stage agent: structures parsed Markdown into concept sections."""

    def __init__(self, curriculum_skill: CurriculumSkill) -> None:
        """Create the agent with its injected Curriculum skill.

        Args:
            curriculum_skill: Skill that turns Markdown into concept sections.
        """
        self._curriculum_skill = curriculum_skill

    async def __call__(self, state: VideoGenerationState) -> dict[str, list[ChapterSection]]:
        """Populate ``sections`` from the state's parsed Markdown content.

        Args:
            state: Current shared pipeline state.

        Returns:
            Partial state update containing the structured concept sections.

        Raises:
            ValueError: If the Intake stage has not yet produced Markdown content.
        """
        if not state.markdown_content:
            raise ValueError("Curriculum agent requires markdown_content from the Intake stage.")
        sections = await self._curriculum_skill.structure_chapter(state.markdown_content)
        return {"sections": sections}


class LessonPlanningAgent:
    """Pedagogy-stage agent: paces concept sections for a Class 6 attention span."""

    def __init__(self, lesson_planning_skill: LessonPlanningSkill) -> None:
        """Create the agent with its injected Lesson Planning skill.

        Args:
            lesson_planning_skill: Skill that applies pacing and content-density constraints.
        """
        self._lesson_planning_skill = lesson_planning_skill

    async def __call__(self, state: VideoGenerationState) -> dict[str, list[ChapterSection]]:
        """Repace ``sections`` from the state's Curriculum-stage output.

        Args:
            state: Current shared pipeline state.

        Returns:
            Partial state update containing the paced concept sections.

        Raises:
            ValueError: If the Curriculum stage has not yet produced sections.
        """
        if not state.sections:
            raise ValueError("Lesson Planning agent requires sections from the Curriculum stage.")
        sections = await self._lesson_planning_skill.apply_pacing(state.sections)
        return {"sections": sections}


class TeacherAgent:
    """Pedagogy-stage agent: rewrites concept sections into localized narration."""

    def __init__(self, teacher_skill: TeacherSkill) -> None:
        """Create the agent with its injected Teacher skill.

        Args:
            teacher_skill: Skill that converts scientific terms into localized language.
        """
        self._teacher_skill = teacher_skill

    async def __call__(self, state: VideoGenerationState) -> dict[str, list[ChapterSection]]:
        """Rewrite ``sections`` from the state's Lesson Planning-stage output.

        Args:
            state: Current shared pipeline state.

        Returns:
            Partial state update containing the localized narration sections.

        Raises:
            ValueError: If the Lesson Planning stage has not yet produced sections.
        """
        if not state.sections:
            raise ValueError("Teacher agent requires sections from the Lesson Planning stage.")
        sections = await self._teacher_skill.localize_sections(state.sections)
        return {"sections": sections}


class StoryboardAgent:
    """Storyboarding-stage agent: turns narration sections into timed scene beats."""

    def __init__(self, storyboard_skill: StoryboardSkill) -> None:
        """Create the agent with its injected Storyboard skill.

        Args:
            storyboard_skill: Skill that produces per-scene visual prompts and timing.
        """
        self._storyboard_skill = storyboard_skill

    async def __call__(self, state: VideoGenerationState) -> dict[str, list[ScriptBeat]]:
        """Populate ``storyboard_beats`` from the state's Teacher-stage output.

        Args:
            state: Current shared pipeline state.

        Returns:
            Partial state update containing the timed storyboard beats.

        Raises:
            ValueError: If the Teacher stage has not yet produced sections.
        """
        if not state.sections:
            raise ValueError("Storyboard agent requires sections from the Teacher stage.")
        storyboard_beats = await self._storyboard_skill.create_storyboard(state.sections)
        return {"storyboard_beats": storyboard_beats}
