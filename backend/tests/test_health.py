"""Health endpoint tests."""

from httpx import ASGITransport, AsyncClient

from app.main import create_app


async def test_health_reports_running_application() -> None:
    """The health endpoint reports liveness and configured environment."""
    app = create_app()
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"
