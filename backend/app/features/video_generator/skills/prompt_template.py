"""Shared YAML prompt-template loading for the Skills layer."""

from pathlib import Path

import yaml


class PromptTemplate:
    """Loads a versioned ``system``/``template`` prompt pair from a YAML file."""

    def __init__(self, path: Path) -> None:
        """Load and parse the prompt template.

        Args:
            path: Path to a YAML file with top-level ``system`` and ``template`` keys.
        """
        prompt_config = yaml.safe_load(path.read_text(encoding="utf-8"))
        self._system: str = prompt_config["system"]
        self._template: str = prompt_config["template"]

    def render(self, **kwargs: str) -> str:
        """Assemble the full prompt by interpolating ``kwargs`` into the template.

        Args:
            kwargs: Values substituted into the template's ``{placeholder}`` fields.

        Returns:
            The system prompt and rendered template joined into one prompt string.
        """
        return f"{self._system}\n\n{self._template.format(**kwargs)}"
