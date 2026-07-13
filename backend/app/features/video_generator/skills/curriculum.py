"""CurriculumSkill: structures raw chapter Markdown into concept blocks."""

from pathlib import Path

import yaml
from pydantic import BaseModel, Field

from app.core.interfaces import ILlmProvider
from app.features.video_generator.models import ChapterSection

_DEFAULT_PROMPT_PATH = Path(__file__).parent / "prompts" / "curriculum.yaml"


class CurriculumResponse(BaseModel):
    """Schema-validated shape of the Curriculum agent's LLM call."""

    sections: list[ChapterSection] = Field(min_length=1)


class CurriculumSkill:
    """Facade that turns chapter Markdown into ``ChapterSection`` concept blocks."""

    def __init__(self, llm_provider: ILlmProvider, prompt_path: Path = _DEFAULT_PROMPT_PATH) -> None:
        """Create the skill with its LLM provider and versioned prompt template.

        Args:
            llm_provider: Provider used to complete the assembled prompt.
            prompt_path: Path to the YAML file holding the ``system``/``template`` prompt parts.
        """
        self._llm_provider = llm_provider
        prompt_config = yaml.safe_load(prompt_path.read_text(encoding="utf-8"))
        self._system_prompt: str = prompt_config["system"]
        self._template: str = prompt_config["template"]

    async def structure_chapter(self, markdown_content: str) -> list[ChapterSection]:
        """Structure chapter Markdown into an ordered list of concept sections.

        Args:
            markdown_content: Markdown produced by the Intake stage.

        Returns:
            Concept sections in chapter order.
        """
        prompt = f"{self._system_prompt}\n\n{self._template.format(markdown_content=markdown_content)}"
        response = await self._llm_provider.complete(prompt, CurriculumResponse)
        return response.sections
