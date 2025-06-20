# GPT Backend

This repository contains:

1. **Flask / SocketIO server** (`app.py`)
   - REST endpoints for chat, transcript history, and audio-to-text.
   - WebSocket events for live audio chunks and transcript pushes.
   - PostgreSQL logging with SQLAlchemy.
   - Rate-limiting with Flask-Limiter.
   - Real-time speech-to-text using `whisper.cpp`, FFmpeg, and Eventlet.

2. **Go feedback microservice** (`analyzer.go`)
   - Simple HTTP endpoint that returns word and character counts for any text.

## Quick Start

### Prerequisites
| Component | Purpose | Notes |
|-----------|---------|-------|
| Python 3.11 | main API | see `requirements.txt` |
| Go 1.20+   | analyzer | only for `analyzer.go` |
| FFmpeg     | audio decode |
| `whisper.cpp` | speech-to-text | built during Docker build |
| PostgreSQL | chat logs | set `DATABASE_URL` |

### 1  Environment File

Create `.env` in the backend root:

```env
OPENAI_API_KEY=your_openai_key
DATABASE_URL=postgresql://user:pass@db:5432/interview_coach
````

### 2  Local Run (without Docker)

```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# build whisper.cpp
git clone https://github.com/ggerganov/whisper.cpp.git
cd whisper.cpp && make && cd ..

# download at least one model
wget -O whisper.cpp/models/ggml-base.en.bin \
     https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin

# initialise DB (once)
python init_db.py

# start Flask-SocketIO server (Eventlet)
python app.py
```

In another shell:

```bash
go run analyzer.go
```

### 3  Docker (recommended)

```bash
docker compose up --build  # if you added a compose file
# OR
docker build -t gpt-backend .
docker run -p 5000:5000 --env-file .env gpt-backend
```

## API Summary

| Method | Path                    | Description                                  |
| ------ | ----------------------- | -------------------------------------------- |
| POST   | `/chat`                 | GPT chat request                             |
| GET    | `/history/<session_id>` | Retrieve stored conversation                 |
| POST   | `/interview/stream`     | Upload one audio blob and receive transcript |

### SocketIO Events

| Event                    | Direction       | Payload                    |
| ------------------------ | --------------- | -------------------------- |
| `connect` / `disconnect` | Server ↔ Client | none                       |
| `audio_chunk`            | Client → Server | raw `ArrayBuffer`          |
| `transcript`             | Server → Client | `{ "text": "<string>" }`   |
| `error`                  | Server → Client | `{ "error": "<message>" }` |

## File Layout

```
backend/
├── app.py               # Flask + SocketIO main server
├── whisper_handler.py   # ffmpeg + whisper.cpp wrapper
├── analyzer.go          # optional Go feedback service
├── init_db.py           # one-time DB creation
├── requirements.txt
├── Dockerfile
└── whisper.cpp/         # cloned & built inside Docker
```

## Useful Notes

* **Eventlet** is monkey-patched at the very top of `app.py` (`eventlet.monkey_patch()`) to keep SocketIO async.
* Audio chunks are recorded \~6 s, sent as `audio/webm`; server converts to 16 kHz mono WAV before running `whisper-cli`.
* For larger models, change `DEFAULT_MODEL` in `whisper_handler.py`.
* The Go microservice is optional. If disabled, `analyze_with_go_service` simply skips feedback scoring.