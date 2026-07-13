"""Video-generation API integration tests."""

import asyncio
import time
from uuid import UUID

from httpx import AsyncClient

from tests.conftest import FAILURE_SENTINEL_PATH

_POLL_TIMEOUT_SECONDS = 15.0
_POLL_INTERVAL_SECONDS = 0.02


async def _wait_for_terminal_status(client: AsyncClient, task_id: str) -> dict[str, object]:
    """Poll a job until it leaves QUEUED/PROCESSING or a wall-clock budget is exhausted.

    Returns:
        The job status payload once it reaches a terminal status.

    Raises:
        AssertionError: If the job does not reach a terminal status in time.
    """
    deadline = time.monotonic() + _POLL_TIMEOUT_SECONDS
    while time.monotonic() < deadline:
        response = await client.get(f"/api/v1/videos/{task_id}")
        payload: dict[str, object] = response.json()
        if payload["status"] not in {"QUEUED", "PROCESSING"}:
            return payload
        await asyncio.sleep(_POLL_INTERVAL_SECONDS)
    raise AssertionError(f"Job {task_id} did not reach a terminal status within {_POLL_TIMEOUT_SECONDS}s.")


async def test_generate_and_read_job_status(client: AsyncClient) -> None:
    """The API creates a queued job and advances it through the Intake stage."""
    response = await client.post(
        "/api/v1/videos/generate",
        json={
            "class_level": "6",
            "subject": "Science",
            "chapter_title": "The World of Plants",
            "file_storage_path": "uploads/chapters/science_ch4.pdf",
        },
    )

    payload = response.json()
    assert response.status_code == 202
    assert UUID(payload["task_id"])
    assert payload["status"] == "QUEUED"

    completed_payload = await _wait_for_terminal_status(client, payload["task_id"])
    assert completed_payload["status"] == "COMPLETED"
    assert "Mock Markdown" in str(completed_payload["markdown_content"])
    assert completed_payload["error_message"] is None


async def test_generate_records_pipeline_failure(client: AsyncClient) -> None:
    """A pipeline failure is recorded on the job instead of crashing the worker."""
    response = await client.post(
        "/api/v1/videos/generate",
        json={
            "class_level": "6",
            "subject": "Science",
            "chapter_title": "The World of Plants",
            "file_storage_path": FAILURE_SENTINEL_PATH,
        },
    )
    payload = response.json()

    failed_payload = await _wait_for_terminal_status(client, payload["task_id"])
    assert failed_payload["status"] == "FAILED"
    assert failed_payload["markdown_content"] is None
    assert "Simulated parser failure" in str(failed_payload["error_message"])


async def test_get_unknown_job_returns_not_found(client: AsyncClient) -> None:
    """The API returns a clear 404 response for an unknown task UUID."""
    response = await client.get("/api/v1/videos/00000000-0000-0000-0000-000000000000")

    assert response.status_code == 404
