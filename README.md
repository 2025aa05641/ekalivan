# Ekalivan

## Democratizing Quality Education Through AI

### கற்போம் • கேட்போம் • பார்ப்போம் • பழகுவோம்

**Karpom • Ketpom • Parpom • Pazhaguvom**

*Learn • Listen • Visualize • Practice*

---

An AI-powered personalized learning platform that empowers every learner through multilingual, curriculum-aligned learning experiences.

Built with ❤️ by **Team 4NLPians** for the **Build in AI for India Hackathon**.

This repository contains the Sprint 0 foundation for the platform defined in the Executive Architecture Design Document. The system keeps AI work on the content-creation path and serves rendered video assets without AI work at playback time.

## Architecture

- `backend/`: Python 3.12 FastAPI API gateway. Routes accept work quickly, background execution owns long-running work, and interfaces isolate LangGraph, LLM providers, and MCP tools.
- `frontend/`: Flutter client using feature-first Clean Architecture, Riverpod for observed async state, Dio for networking, and GoRouter named routes.
- `mcp_demo/`: Existing exploratory notebook; it is not part of the production application.

Sprint 1 persists accepted generation jobs and runs a temporary background status lifecycle. The generation graph, media tooling, and local asset cache remain scheduled for later sprints.

## Run the backend

Python 3.12 is required.

```bash
cd backend
python3.12 -m venv .venv
source .venv/bin/activate
pip install -e '.[dev]'
cp ../.env.example .env
alembic upgrade head
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Useful endpoints: `GET /health`, `POST /api/v1/videos/generate`, and `GET /api/v1/videos/{task_id}`.

## Run the development stack with Docker

Create the local environment file, then start PostgreSQL and the backend:

```bash
cp .env.example .env
docker compose up -d
docker compose exec backend alembic upgrade head
```

The backend is available at `http://localhost:8000`; its health endpoint is `http://localhost:8000/health`. Source changes under `backend/` reload automatically in the development container.

View service logs or stop the stack:

```bash
docker compose logs -f backend
docker compose down
```

Use `docker compose down -v` only when you intend to remove the persistent local PostgreSQL data volume.

Run backend checks:

```bash
cd backend
ruff check .
black --check .
mypy app
pytest --cov=app --cov-fail-under=80
```

## Run the Flutter client

Install the latest stable Flutter SDK, then:

```bash
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8000
flutter analyze
flutter test
```

For an Android emulator, replace `localhost` with the host alias appropriate to that emulator (commonly `10.0.2.2`).

## API contract

`POST /api/v1/videos/generate` accepts `class_level`, `subject`, and `chapter_title`; it returns `202 Accepted` and a UUID-backed queued task. Query `GET /api/v1/videos/{task_id}` for its current status. Sprint 1 advances the job through a mock `QUEUED → PROCESSING → COMPLETED` lifecycle; no video is generated yet.

## Environment

Copy `.env.example` to `.env` and set the PostgreSQL credentials and `DATABASE_URL` for local execution. Docker Compose automatically provides the backend container with a database URL that targets the `postgres` service. Run `alembic upgrade head` before using database-backed endpoints. The Flutter API base URL is supplied through `--dart-define`, keeping environment-specific values out of source control.
