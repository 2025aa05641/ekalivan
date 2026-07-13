"""StoryboardSkill: turns localized narration sections into timed scene beats."""

import json
from pathlib import Path

from pydantic import BaseModel, Field

from app.core.interfaces import ILlmProvider
from app.features.video_generator.models import ChapterSection, ScriptBeat
from app.features.video_generator.skills.prompt_template import PromptTemplate

_DEFAULT_PROMPT_PATH = Path(__file__).parent / "prompts" / "storyboard.yaml"


class StoryboardResponse(BaseModel):
    """Schema-validated shape of the Storyboard agent's LLM call."""

    beats: list[ScriptBeat] = Field(min_length=1)


class StoryboardSkill:
    """Facade that turns narration sections into per-scene visual prompts and timing."""

    def __init__(self, llm_provider: ILlmProvider, prompt_path: Path = _DEFAULT_PROMPT_PATH) -> None:
        """Create the skill with its LLM provider and versioned prompt template.

        Args:
            llm_provider: Provider used to complete the assembled prompt.
            prompt_path: Path to the YAML file holding the ``system``/``template`` prompt parts.
        """
        self._llm_provider = llm_provider
        self._prompt = PromptTemplate(prompt_path)

    async def create_storyboard(self, sections: list[ChapterSection]) -> list[ScriptBeat]:
        """Turn localized narration sections into timed storyboard beats.

        Args:
            sections: Localized narration sections produced by the Teacher stage.

        Returns:
            Storyboard beats in scene order.
        """
        sections_json = json.dumps([section.model_dump() for section in sections])
        prompt = self._prompt.render(sections_json=sections_json)
        response = await self._llm_provider.complete(prompt, StoryboardResponse)
        return response.beats
