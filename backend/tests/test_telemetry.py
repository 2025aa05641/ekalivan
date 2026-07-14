"""Unit tests for per-stage pipeline telemetry."""

import logging

import pytest

from app.core.telemetry import with_node_telemetry
from app.features.video_generator.models import VideoGenerationState


async def test_with_node_telemetry_logs_success_outcome(caplog: pytest.LogCaptureFixture) -> None:
    """A successful node call is logged with the stage name, task id, and outcome."""

    async def _node(state: VideoGenerationState) -> dict[str, str]:
        return {"markdown_content": "ok"}

    wrapped = with_node_telemetry("parser", _node)
    with caplog.at_level(logging.INFO, logger="app.telemetry"):
        result = await wrapped(VideoGenerationState(file_path="chapter.pdf", task_id="job-1"))

    assert result == {"markdown_content": "ok"}
    assert "stage=parser" in caplog.text
    assert "task_id=job-1" in caplog.text
    assert "outcome=succeeded" in caplog.text


async def test_with_node_telemetry_logs_failure_outcome_and_reraises(caplog: pytest.LogCaptureFixture) -> None:
    """A failing node's exception still propagates, with a failure outcome logged first."""

    async def _node(state: VideoGenerationState) -> dict[str, str]:
        raise RuntimeError("boom")

    wrapped = with_node_telemetry("narration", _node)
    with caplog.at_level(logging.INFO, logger="app.telemetry"), pytest.raises(RuntimeError, match="boom"):
        await wrapped(VideoGenerationState(file_path="chapter.pdf", task_id="job-2"))

    assert "stage=narration" in caplog.text
    assert "outcome=failed" in caplog.text
