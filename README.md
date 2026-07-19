# Ekalivan

## Democratizing Quality Education Through AI

### கற்போம் • கேட்போம் • பார்ப்போம் • பழகுவோம்

**Karpom • Ketpom • Parpom • Pazhaguvom**

*Learn • Listen • Visualize • Practice*

---

An AI-powered personalized learning platform that empowers every learner through multilingual, curriculum-aligned learning experiences.

Built with ❤️ by **Team 4NLPians** for the **Build in AI for India Hackathon** — shortlisted in the competition.

Ekalivan turns a static government-school textbook chapter into a short, localized, animated video lesson — automatically, using AI once at content-creation time and never again at playback time. A **Creator** (teacher/publisher) uploads a chapter PDF once; every **Student** afterwards streams the finished video for free, with zero further AI cost.

## Documentation & Demo

- [`APP_FUNCTIONALITY_AND_EXECUTIVE_SUMMARY.md`](APP_FUNCTIONALITY_AND_EXECUTIVE_SUMMARY.md) / [`.pdf`](APP_FUNCTIONALITY_AND_EXECUTIVE_SUMMARY.pdf) — product overview: problem, personas, pipeline, tech stack.
- [`Executive_Architecture_Design_Document (1).md`](Executive_Architecture_Design_Document%20%281%29.md) / [`Executive_Architecture_Design_Document.pdf`](Executive_Architecture_Design_Document.pdf) — full architecture design document.
- [`Final_Demo/`](Final_Demo/) — final demo deliverables: the narrated slide video (`Ekalivan_Slides_Narrated.mp4`), the slide deck (`Ekalaivan_FinalDemo.pptx`), and a full walkthrough recording (`final_demo.mp4`).

## Architecture

- `backend/`: Python 3.12 FastAPI API gateway. Routes accept work quickly, background execution owns long-running work, and interfaces isolate LangGraph, LLM providers, and MCP tools.
- `frontend/`: Flutter client using feature-first Clean Architecture, Riverpod for observed async state, Dio for networking, and GoRouter named routes. It splits into a **Creator Portal** (login, dashboard, upload book, pipeline/rendering progress, publish, libraries) and a **Student Portal** (splash, medium/class/subject selection, chapter list, chapter detail with video playback, downloads, profile).
- `mcp_demo/`: Existing exploratory notebook; it is not part of the production application.
- `Final_Demo/`: Final demo deliverables — see Documentation & Demo above.

The system is a working end-to-end product: a Creator can upload a PDF, watch it move through an 8-stage AI pipeline (Parser/Intake → Curriculum → Lesson Planning → Teacher → Storyboard → Narration/TTS → Video Rendering → Publishing), and publish a real streamable MP4; a Student can pick a medium, class, and subject and watch the resulting lesson. Every LLM-backed stage runs through a single `ILlmProvider` interface against a local Ollama server (with optional fallback chaining), narration audio and word-level timestamps come from Edge TTS, and rendering composites the result into one streaming-ready MP4 via MoviePy and FFmpeg — with a pluggable clip source (`local`, Google Veo 3, or pre-generated Kaggle clips) for the video's visuals.

## Run the backend

Python 3.12 is required.

The Pedagogy and Storyboarding stages (Curriculum, Lesson Planning, Teacher, Storyboard) call a local [Ollama](https://ollama.com) server; install it and pull the configured model (`llama3.1` by default) before generating a video, or the pipeline will complete Intake and then fail explicitly at the first LLM-backed stage:

```bash
ollama pull llama3.1
```

The Narration stage calls Microsoft's Edge TTS service over the network (no API key, but not local/offline like the other stages) to synthesize each storyboard beat's audio and capture word-level timestamps. Audio files are written under `<STATIC_ASSETS_PATH>/audio/<task_id>/`.

The Video Rendering stage composites those beats into one video via MoviePy and FFmpeg, both bundled and run locally (no network, no API key). No image-generation tool exists yet — `FutureImageGenerationTool` in the architecture document is an explicit placeholder, not an MVP feature — so each beat renders as a solid-color card with its narration burned in as a caption, not an illustration. Rendered video files are written under `<STATIC_ASSETS_PATH>/video/<task_id>/final.mp4`.

The Publishing stage validates that file, writes a `manifest.json` cache-manifest entry next to it, and returns a `video_url`. The backend serves the whole `<STATIC_ASSETS_PATH>` tree at `/static`, so a completed job's video is playable directly at `http://localhost:8000<video_url>`.

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

To run in a browser instead, the dev server's origin must be in the backend's `ALLOWED_ORIGINS` (the default already includes `http://localhost:5057`):

```bash
flutter run -d chrome --web-port=5057 --dart-define=API_BASE_URL=http://localhost:8000
```

The app opens on a role-select screen splitting into the Creator Portal and Student Portal described above. The fully-wired demo path is: Creator uploads a Grade 6 Science PDF → the pipeline runs → Creator previews and publishes → Student picks English/Tamil → Grade 6 → Science → Chapter 1 ("The World of Plants") → watches the lesson. Content outside that path (other grades/subjects/chapters) may still be placeholder UI. A standalone, portal-agnostic generation flow (`/generate`, `/videos/:taskId`, `/my-videos`) inherited from earlier sprints remains available for testing the pipeline independent of either portal.

## API contract

`POST /api/v1/videos/upload` accepts a multipart PDF upload and returns a `file_storage_path` for use in `/generate`. `POST /api/v1/videos/generate` accepts `class_level`, `subject`, `chapter_title`, and `file_storage_path`; it returns `202 Accepted` and a UUID-backed queued task. Query `GET /api/v1/videos/{task_id}` for its current status. `GET /api/v1/videos/` lists recent jobs and `GET /api/v1/videos/metrics` returns aggregate job counts and mean completion time for the Creator dashboard. The job moves through `QUEUED → PROCESSING → COMPLETED` (or `FAILED`, with `error_message` set) as it runs the Intake stage (MarkItDown parses the source file to Markdown), the Pedagogy stages (Curriculum structures that Markdown into concept `sections`, Lesson Planning paces them for a Class 6 lesson, and Teacher rewrites them into localized narration), the Storyboarding stage (turning those sections into timed `storyboard_beats`), the Narration stage (synthesizing each beat's audio and word-level timing into `narrated_beats`), the Video Rendering stage (compositing those beats into `output_video_path`), and the Publishing stage (validating that file and returning it as a servable `video_url`).

## Environment

Copy `.env.example` to `.env` and set the PostgreSQL credentials, `DATABASE_URL`, and Ollama settings (`OLLAMA_BASE_URL`, `OLLAMA_MODEL`) for local execution. Docker Compose automatically provides the backend container with a database URL that targets the `postgres` service and an Ollama URL that targets the host machine. Run `alembic upgrade head` before using database-backed endpoints. The Flutter API base URL is supplied through `--dart-define`, keeping environment-specific values out of source control.
