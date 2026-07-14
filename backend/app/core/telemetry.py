"""Structured per-stage timing telemetry for the LangGraph pipeline."""

import logging
import time
from collections.abc import Awaitable, Callable
from typing import Any

from app.features.video_generator.models import VideoGenerationState

logger = logging.getLogger("app.telemetry")

NodeFn = Callable[[VideoGenerationState], Awaitable[dict[str, Any]]]


class _TelemetryNode:
    """Callable node wrapper that logs one structured line per invocation."""

    def __init__(self, stage_name: str, node: NodeFn) -> None:
        """Create the wrapper around ``node``, logged under ``stage_name``.

        Args:
            stage_name: Name the pipeline stage is logged under, e.g. ``"narration"``.
            node: The agent callable to wrap.
        """
        self._stage_name = stage_name
        self._node = node

    async def __call__(self, state: VideoGenerationState) -> dict[str, Any]:
        """Run the wrapped node, logging its duration and outcome.

        Args:
            state: Current shared pipeline state.

        Returns:
            Whatever the wrapped node returns.
        """
        start = time.monotonic()
        try:
            result = await self._node(state)
        except Exception:
            logger.info(
                "pipeline_stage stage=%s task_id=%s duration_seconds=%.3f outcome=failed",
                self._stage_name,
                state.task_id,
                time.monotonic() - start,
            )
            raise
        logger.info(
            "pipeline_stage stage=%s task_id=%s duration_seconds=%.3f outcome=succeeded",
            self._stage_name,
            state.task_id,
            time.monotonic() - start,
        )
        return result


def with_node_telemetry(stage_name: str, node: NodeFn) -> _TelemetryNode:
    """Wrap a LangGraph node so its duration and outcome are logged structurally.

    Args:
        stage_name: Name the pipeline stage is logged under, e.g. ``"narration"``.
        node: The agent callable to wrap.

    Returns:
        A callable with the same signature that logs one structured line per call.
    """
    return _TelemetryNode(stage_name, node)
