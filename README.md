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

Sprint 1 persists accepted generation jobs and runs a background status lifecycle. Sprint 2 wires the Intake stage (MarkItDown) into a real LangGraph pipeline. Sprints 3–4 add the Pedagogy stages — Curriculum, Lesson Planning, and Teacher — each an LLM-backed node calling a local Ollama server through the LLM Provider Layer. Sprint 5 adds the Storyboard stage, turning localized narration into timed scene beats. The remaining pipeline stages, media tooling, and local asset cache remain scheduled for later sprints.

## Run the backend

Python 3.12 is required. The Pedagogy and Storyboarding stages (Curriculum, Lesson Planning, Teacher, Storyboard) call a local [Ollama](https://ollama.com) server; install it and pull the configured model (`llama3.1` by default) before generating a video, or the pipeline will complete Intake and then fail explicitly at the first LLM-backed stage:

```bash
ollama pull llama3.1
```

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

The backend is available at `http://localhost:8000`; its health endpoint is `http://localhost:8000/health`. Source changes under `backend/` reload automatically in the development container. The container reaches Ollama on the host via `host.docker.internal`, which `docker-compose.yml` maps for you — run Ollama on the host machine, not inside the stack.

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

`POST /api/v1/videos/generate` accepts `class_level`, `subject`, `chapter_title`, and `file_storage_path`; it returns `202 Accepted` and a UUID-backed queued task. Query `GET /api/v1/videos/{task_id}` for its current status. The job moves through `QUEUED → PROCESSING → COMPLETED` (or `FAILED`, with `error_message` set) as it runs the Intake stage (MarkItDown parses the source file to Markdown), the Pedagogy stages (Curriculum structures that Markdown into concept `sections`, Lesson Planning paces them for a Class 6 lesson, and Teacher rewrites them into localized narration), and the Storyboarding stage (turning those sections into timed `storyboard_beats`); no video is rendered yet.

## Environment

Copy `.env.example` to `.env` and set the PostgreSQL credentials, `DATABASE_URL`, and Ollama settings (`OLLAMA_BASE_URL`, `OLLAMA_MODEL`) for local execution. Docker Compose automatically provides the backend container with a database URL that targets the `postgres` service and an Ollama URL that targets the host machine. Run `alembic upgrade head` before using database-backed endpoints. The Flutter API base URL is supplied through `--dart-define`, keeping environment-specific values out of source control.
