"""Structured process logging configuration."""

import logging


def configure_logging(log_level: str) -> None:
    """Configure deterministic console logging once at application startup."""
    logging.basicConfig(level=log_level.upper(), format="%(asctime)s %(levelname)s %(name)s %(message)s", force=True)
