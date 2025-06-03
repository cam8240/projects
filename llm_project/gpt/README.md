# LLM Chat Assistant – Independent Project

This directory contains a full-stack conversational AI assistant built using OpenAI's API. The project showcases back-end Flask development, front-end rendering with markdown and code highlighting, and integration of rate limiting, CORS, and secure key handling. It is designed as a locally hosted application with a browser interface, optional bash-based CLI, and an integrated Go microservice.

## Overview

The assistant supports multiple interaction modes—"friendly," "tutor," and "coder"—allowing dynamic personality control via system prompts. The UI is rendered in dark mode, and responses are formatted to handle code, tables, and inline markdown cleanly. Sessions are logged to a PostgreSQL database, and the app is suitable for lightweight experimentation or as a foundation for more advanced LLM applications.

## Features

* Flask back-end with RESTful `/chat` and `/history/<session_id>` endpoints.
* OpenAI API integration (GPT-4.1-nano).
* Secure `.env` key handling and environment variable loading.
* PostgreSQL-based session logging via SQLAlchemy.
* Web UI supporting markdown, code blocks, and tables.
* Bash script interface for terminal-based interaction via cURL.
* Go-based microservice (`analyzer.go`) for text analysis integration.

## Structure

The project consists of:

* `app.py`: Python Flask server with OpenAI API logic, SQL persistence, and rate limiting.
* `index.html`: Front-end UI with Markdown rendering and syntax highlighting.
* `ask.sh`: Bash script for terminal-based interaction.
* `analyzer.go`: Go microservice for external text analysis.
* `init_db.py`: Script for initializing the PostgreSQL schema.
* `run_all.sh`: Bash script for executing all files.

Run:
1. `python3 ./init_db.py` (only after changing schema/model)
2. `python3 ./app.py`
3. `python3 -m http.server`
**OR THIS**:  
   `./run_all.sh`
4. Open in browser: `http://localhost:8000/index.html`

## Purpose

This project demonstrates the ability to integrate third-party LLM services into a secure, functional web app. It highlights practical skills in API handling, session management, SQL integration, front-end markup rendering, and interface design. The inclusion of a Go microservice showcases microservice architecture and cross-language extensibility.

## License

© 2025 Cameron Marchese. All rights reserved. This project is shared for demonstration purposes only. Redistribution of API keys or hosted endpoints is prohibited.
