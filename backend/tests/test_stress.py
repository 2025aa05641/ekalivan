"""End-to-end stress test: high-volume concurrent submissions against a capped queue.

Uses fast, deterministic stand-ins for the MoviePy/FFmpeg/TTS tools so the test
runs in seconds rather than minutes; the concurrency cap, background-task
scheduling, and database layer are all real. A separate, smaller live run
against the real pipeline (real Ollama/MoviePy/FFmpeg) is documented in the
Sprint 11 summary rather than encoded here, since a 20-job real render would
take the better part of an hour on this machine.
"""

import asyncio
from uuid import UUID

from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.main import create_app
from tests.conftest import (
    FakeCompositionTool,
    FakeEncodeTool,
    FakeLlmProvider,
    FakeParserTool,
    FakeStorageTool,
    FakeTtsTool,
)

_STRESS_JOB_COUNT = 20
_RENDER_SLOT_CAP = 3
_SAFETY_TIMEOUT_SECONDS = 60.0

_GENERATE_PAYLOAD = {
    "class_level": "6",
    "subject": "Science",
    "chapter_title": "The World of Plants",
    "file_storage_path": "uploads/chapters/science_ch4.pdf",
}


async def test_high_volume_concurrent_submissions_all_complete_without_cross_job_corruption(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    """20 simultaneous submissions against a 3-slot cap all complete correctly and in isolation."""
    app = create_app(
        session_factory=session_factory,
        parser_tool=FakeParserTool(),
        llm_provider=FakeLlmProvider(),
        tts_tool=FakeTtsTool(),
        composition_tool=FakeCompositionTool(),
        encode_tool=FakeEncodeTool(),
        storage_tool=FakeStorageTool(),
        max_concurrent_render_jobs=_RENDER_SLOT_CAP,
    )
    background_tasks: set[asyncio.Task[None]] = app.state.background_tasks

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        responses = await asyncio.gather(
            *(client.post("/api/v1/videos/generate", json=_GENERATE_PAYLOAD) for _ in range(_STRESS_JOB_COUNT))
        )
        assert all(response.status_code == 202 for response in responses)
        task_ids = [response.json()["task_id"] for response in responses]
        assert len({UUID(task_id) for task_id in task_ids}) == _STRESS_JOB_COUNT

        await asyncio.wait_for(
            asyncio.gather(*background_tasks, return_exceptions=True), timeout=_SAFETY_TIMEOUT_SECONDS
        )

        status_payloads = await asyncio.gather(*(client.get(f"/api/v1/videos/{task_id}") for task_id in task_ids))
        for task_id, response in zip(task_ids, status_payloads, strict=True):
            payload = response.json()
            assert payload["status"] == "COMPLETED", payload
            assert payload["task_id"] == task_id

        metrics_response = await client.get("/api/v1/videos/metrics")
        metrics = metrics_response.json()
        assert metrics["total_jobs"] == _STRESS_JOB_COUNT
        assert metrics["counts_by_status"] == {"COMPLETED": _STRESS_JOB_COUNT}
