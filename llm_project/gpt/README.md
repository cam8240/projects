# LLM Chat Assistant – Independent Project

This directory contains a full-stack conversational AI assistant built using OpenAI's API.
The stack now includes **three clients**:

| Client           | Tech             | Purpose                |
| ---------------- | ---------------- | ---------------------- |
| **Vue Web**      | Vue + Nginx      | Browser-based UI       |
| **CLI**          | Bash             | Quick terminal access  |
| **Java Desktop** | Java 17 + JavaFX | Stand-alone desktop UI |

All clients share the same Flask back-end, PostgreSQL storage, and Go / Java services, and everything is containerised with Docker Compose.

---

## Overview

The assistant supports multiple interaction modes—“friendly,” “tutor,” and “coder”—allowing dynamic personality control via system prompts.
Sessions are logged to PostgreSQL and analysed by a Go microservice; longer-running tasks can be off-loaded to the new Java desktop client.
The web UI renders dark-mode markdown; the JavaFX client provides a native-window alternative.

The system has also been expanded with an interactive `/coach` page:
Users can stream live microphone audio directly to the Flask server (via WebSocket), where it is transcribed using `whisper.cpp`.
Incoming transcripts are analysed in real-time for pace, filler words, and structure, and GPT generates dynamic coaching tips based on the results.

---

## Features

* Flask back-end with RESTful `/chat` and `/history/<session_id>` endpoints.
* **JavaFX desktop client** (`desktop-client/`) with chat window, local message cache, and OpenAI calls via HTTP.
* OpenAI API integration (GPT-4.1-nano).
* PostgreSQL session logging with SQLAlchemy.
* Rate limiting via Flask-Limiter.
* Markdown and syntax-highlighted web UI.
* Go microservice (`analyzer.go`) for word / character analytics.
* Docker-based full-stack orchestration.
* Bash script for CLI interaction.
* Vue `/coach` tool with mic access, WebSocket streaming, live transcription via `whisper.cpp`, and feedback generation.

---

## Structure

```
.
├── backend/
│   ├── app.py
│   ├── analyzer.go
│   ├── Dockerfile
│   ├── Dockerfile.analyzer
│   ├── requirements.txt
│   └── instance/chat.db
│
├── frontend/
│   ├── Dockerfile
│   └── [Vue App Files]
│
├── desktop-client/
│   ├── src/
│   ├── pom.xml          # Maven dependencies
│   ├── Dockerfile       # Optional Java image
│   └── README.md        # Local run instructions
│
├── .env
├── docker-compose.yml
├── ask.sh
└── README.md
```

---

## Running with Docker

Build and start **all containers (web UI, back-end, Go analyser, Postgres)**:

```bash
docker-compose up --build
```

[http://localhost:8080](http://localhost:8080)

Run detached:

```bash
docker-compose up -d
```

Stop:

```bash
docker-compose down
```

### Rebuilding a single service

```bash
docker-compose build frontend
docker-compose build backend
docker-compose build desktop-client
```

### Logs

```bash
docker-compose logs backend
docker-compose logs desktop-client
```

---

## Running the Java Desktop Client Locally

> Requires JDK 17 + Maven 3.8+

```bash
cd desktop-client
mvn clean javafx:run
```

To package a runnable JAR:

```bash
mvn clean package
java -jar target/desktop-client-1.0.0.jar
```

---

## Vue Development with Hot Reload

```bash
cd frontend
npm install
npm run dev    # http://localhost:5173
```

Ensure the Flask back-end (`localhost:5000`) has CORS enabled for local dev.

---

## Viewing Messages with `curl`

```bash
curl http://localhost:5000/history/default
```

To list session IDs (temporary route):

```python
@app.route("/sessions", methods=["GET"])
def list_sessions():
    sessions = db.session.query(ChatLog.session_id).distinct().all()
    return jsonify([s[0] for s in sessions])
```

```bash
curl http://localhost:5000/sessions
```

---

## Purpose

This project demonstrates how to embed third-party LLM services in a secure, multi-client application.
It showcases API handling, session management, cross-language micro-services, and both web & native desktop UIs.
New additions show how to process real-time audio via WebSocket and generate feedback using Whisper and GPT together.

---

## License

© 2025 Cameron Marchese. All rights reserved.
This project is shared for demonstration purposes only; redistribution of API keys or hosted endpoints is prohibited.
