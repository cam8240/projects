# LLM Chat Assistant – Independent Project

This directory contains a full-stack conversational AI assistant built using OpenAI's API. The project showcases back-end Flask development, front-end rendering with markdown and code highlighting, and integration of rate limiting, CORS, PostgreSQL, and a Go-based microservice. It is designed as a locally hosted application with a browser interface, CLI support, and full Docker containerization.

## Overview

The assistant supports multiple interaction modes—"friendly," "tutor," and "coder"—allowing dynamic personality control via system prompts. The UI is rendered in dark mode, and responses are formatted to handle code, tables, and inline markdown cleanly. Sessions are logged to a PostgreSQL database and analyzed via a Go microservice, all running in Docker containers.

## Features

* Flask back-end with RESTful `/chat` and `/history/<session_id>` endpoints.
* OpenAI API integration (GPT-4.1-nano).
* PostgreSQL session logging using SQLAlchemy.
* Rate limiting with Flask-Limiter.
* Markdown and syntax-highlighted UI.
* Go microservice (`analyzer.go`) for word and character analysis.
* Docker-based full-stack orchestration.
* Bash script for CLI-based interaction.

## Structure

```

.
├── backend/
│   ├── app.py               # Flask app
│   ├── analyzer.go          # Go microservice
│   ├── Dockerfile           # Flask Dockerfile
│   ├── Dockerfile.analyzer  # Go service Dockerfile
│   ├── requirements.txt     # Python dependencies
│   └── instance/chat.db     # Local DB file (if SQLite used initially)
│
├── frontend/
│   ├── Dockerfile           # Vue/Nginx container
│   └── \[Vue App Files]      # Vue project output
│
├── .env                     # OpenAI key + DB credentials
├── docker-compose.yml       # Full stack orchestration
├── ask.sh                   # CLI utility for chat
└── README.md

````

## Running with Docker

Build and start everything using:

```bash
docker-compose up --build
````

Or run detached (in background):

```bash
docker-compose up -d
```

To stop all containers:

```bash
docker-compose down
```

To rebuild a specific service:

```bash
docker-compose build frontend
docker-compose build backend
```

To view logs from a service:

```bash
docker-compose logs backend
docker-compose logs frontend
```

To open a shell inside the backend container:

```bash
docker exec -it <container_name_or_id> /bin/sh
```

## Vue Development with Hot Reload

To test the Vue frontend with hot module replacement (HMR), run it locally (outside Docker):

1. Navigate to the frontend directory:

```bash
cd frontend
```

2. Install dependencies:

```bash
npm install
```

3. Start the dev server (instant-refresh):

```bash
npm run dev
```

The app will be live at [http://localhost:5173](http://localhost:5173), with full hot reload for component updates.

Make sure your Flask backend at `localhost:5000` has CORS enabled for local dev.

## Viewing Messages with `curl`

To see message history for a session:

```bash
curl http://localhost:5000/history/default
```

To list all session IDs:

Add this temporary route to `app.py`:

```python
@app.route("/sessions", methods=["GET"])
def list_sessions():
    sessions = db.session.query(ChatLog.session_id).distinct().all()
    return jsonify([s[0] for s in sessions])
```

Then run:

```bash
curl http://localhost:5000/sessions
```

## Purpose

This project demonstrates the ability to integrate third-party LLM services into a secure, functional web app. It highlights practical skills in API handling, session management, SQL integration, front-end markup rendering, and interface design. The inclusion of a Go microservice showcases microservice architecture and cross-language extensibility.

## License

© 2025 Cameron Marchese. All rights reserved. This project is shared for demonstration purposes only. Redistribution of API keys or hosted endpoints is prohibited.