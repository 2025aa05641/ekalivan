"""LessonPlanningSkill: applies Class 6 pacing and content-density constraints."""

import json
from pathlib import Path

from pydantic import BaseModel, Field

from app.core.interfaces import ILlmProvider
from app.features.video_generator.models import ChapterSection
from app.features.video_generator.skills.prompt_template import PromptTemplate

_DEFAULT_PROMPT_PATH = Path(__file__).parent / "prompts" / "lesson_planning.yaml"


class LessonPlanningResponse(BaseModel):
    """Schema-validated shape of the Lesson Planning agent's LLM call."""

    sections: list[ChapterSection] = Field(min_length=1)


class LessonPlanningSkill:
    """Facade that paces concept sections to fit a Class 6 attention span."""

    def __init__(self, llm_provider: ILlmProvider, prompt_path: Path = _DEFAULT_PROMPT_PATH) -> None:
        """Create the skill with its LLM provider and versioned prompt template.

        Args:
            llm_provider: Provider used to complete the assembled prompt.
            prompt_path: Path to the YAML file holding the ``system``/``template`` prompt parts.
        """
        self._llm_provider = llm_provider
        self._prompt = PromptTemplate(prompt_path)

    async def apply_pacing(self, sections: list[ChapterSection]) -> list[ChapterSection]:
        """Merge, split, or cap concept sections to fit a short Class 6 lesson.

        Args:
            sections: Concept sections produced by the Curriculum stage.

        Returns:
            Paced concept sections in chapter order.
        """
        sections_json = json.dumps([section.model_dump() for section in sections])
        prompt = self._prompt.render(sections_json=sections_json)
        response = await self._llm_provider.complete(prompt, LessonPlanningResponse)
        return response.sections
