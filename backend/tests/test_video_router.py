"""Video-generation API integration tests."""

import asyncio
from uuid import UUID

from httpx import AsyncClient


async def test_generate_and_read_job_status(client: AsyncClient) -> None:
    """The API creates a queued job and exposes its mock lifecycle status."""
    response = await client.post(
        "/api/v1/videos/generate",
        json={"class_level": "6", "subject": "Science", "chapter_title": "The World of Plants"},
    )

    payload = response.json()
    assert response.status_code == 202
    assert UUID(payload["task_id"])
    assert payload["status"] == "QUEUED"

    status_response = await client.get(f"/api/v1/videos/{payload['task_id']}")
    assert status_response.status_code == 200
    assert status_response.json()["status"] == "QUEUED"

    await asyncio.sleep(0.03)
    completed_response = await client.get(f"/api/v1/videos/{payload['task_id']}")
    assert completed_response.json()["status"] == "COMPLETED"


async def test_get_unknown_job_returns_not_found(client: AsyncClient) -> None:
    """The API returns a clear 404 response for an unknown task UUID."""
    response = await client.get("/api/v1/videos/00000000-0000-0000-0000-000000000000")

    assert response.status_code == 404
