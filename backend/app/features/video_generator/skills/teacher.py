"""TeacherSkill: converts scientific terms into localized, student-friendly language."""

import json
from pathlib import Path

from pydantic import BaseModel, Field

from app.core.interfaces import ILlmProvider
from app.features.video_generator.models import ChapterSection
from app.features.video_generator.skills.prompt_template import PromptTemplate

_DEFAULT_PROMPT_PATH = Path(__file__).parent / "prompts" / "teacher.yaml"


class TeacherResponse(BaseModel):
    """Schema-validated shape of the Teacher agent's LLM call."""

    sections: list[ChapterSection] = Field(min_length=1)


class TeacherSkill:
    """Facade that rewrites concept sections into localized narration script."""

    def __init__(self, llm_provider: ILlmProvider, prompt_path: Path = _DEFAULT_PROMPT_PATH) -> None:
        """Create the skill with its LLM provider and versioned prompt template.

        Args:
            llm_provider: Provider used to complete the assembled prompt.
            prompt_path: Path to the YAML file holding the ``system``/``template`` prompt parts.
        """
        self._llm_provider = llm_provider
        self._prompt = PromptTemplate(prompt_path)

    async def localize_sections(self, sections: list[ChapterSection]) -> list[ChapterSection]:
        """Rewrite section content into localized, student-friendly narration.

        Args:
            sections: Paced concept sections produced by the Lesson Planning stage.

        Returns:
            The same sections with content rewritten as spoken narration.
        """
        sections_json = json.dumps([section.model_dump() for section in sections])
        prompt = self._prompt.render(sections_json=sections_json)
        response = await self._llm_provider.complete(prompt, TeacherResponse)
        return response.sections
