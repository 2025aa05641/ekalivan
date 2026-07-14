"""Video-generation API integration tests."""

import asyncio
from uuid import UUID

from fastapi import FastAPI
from httpx import AsyncClient

from tests.conftest import FAILURE_SENTINEL_PATH

_BACKGROUND_TASK_SAFETY_TIMEOUT_SECONDS = 30.0


async def _await_generation_and_fetch_status(client: AsyncClient, app: FastAPI, task_id: str) -> dict[str, object]:
    """Await the job's background pipeline task directly, then fetch its final status.

    Awaiting the task itself (instead of polling with a wall-clock budget) makes the
    test deterministic regardless of how slowly the pipeline happens to be scheduled.

    Returns:
        The job status payload once its background task has finished.

    Raises:
        AssertionError: If no background task is registered for the job.
    """
    background_tasks: set[asyncio.Task[None]] = app.state.background_tasks
    if not background_tasks:
        raise AssertionError(f"No background task was scheduled for job {task_id}.")
    await asyncio.wait_for(
        asyncio.gather(*background_tasks, return_exceptions=True), timeout=_BACKGROUND_TASK_SAFETY_TIMEOUT_SECONDS
    )
    response = await client.get(f"/api/v1/videos/{task_id}")
    payload: dict[str, object] = response.json()
    return payload


async def test_generate_and_read_job_status(client: AsyncClient, test_app: FastAPI) -> None:
    """The API creates a queued job and advances it through the full wired pipeline."""
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

    completed_payload = await _await_generation_and_fetch_status(client, test_app, payload["task_id"])
    assert completed_payload["status"] == "COMPLETED"
    assert "Mock Markdown" in str(completed_payload["markdown_content"])
    assert completed_payload["sections"] == [{"title": "Mock Section", "content": "Mock content."}]
    assert completed_payload["storyboard_beats"] == [
        {"narration": "Mock narration.", "visual_prompt": "Mock visual.", "duration_seconds": 5.0}
    ]
    narrated_beats = completed_payload["narrated_beats"]
    assert isinstance(narrated_beats, list)
    assert len(narrated_beats) == 1
    assert narrated_beats[0]["word_timestamps"] == [{"word": "Mock", "start_seconds": 0.0, "end_seconds": 0.5}]
    assert isinstance(completed_payload["output_video_path"], str)
    assert completed_payload["output_video_path"].endswith("final.mp4")
    assert completed_payload["error_message"] is None


async def test_generate_records_pipeline_failure(client: AsyncClient, test_app: FastAPI) -> None:
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

    failed_payload = await _await_generation_and_fetch_status(client, test_app, payload["task_id"])
    assert failed_payload["status"] == "FAILED"
    assert failed_payload["markdown_content"] is None
    assert failed_payload["sections"] is None
    assert failed_payload["storyboard_beats"] is None
    assert failed_payload["narrated_beats"] is None
    assert failed_payload["output_video_path"] is None
    assert "Simulated parser failure" in str(failed_payload["error_message"])


async def test_get_unknown_job_returns_not_found(client: AsyncClient) -> None:
    """The API returns a clear 404 response for an unknown task UUID."""
    response = await client.get("/api/v1/videos/00000000-0000-0000-0000-000000000000")

    assert response.status_code == 404
