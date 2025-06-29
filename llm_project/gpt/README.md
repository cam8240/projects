# LLM Chat Assistant – Independent Project

This directory contains a full-stack conversational AI assistant built using OpenAI's API. The project showcases back-end Flask development, front-end rendering with markdown and code highlighting, and integration of rate limiting, CORS, and secure key handling. It is designed as a locally hosted application with a browser interface and optional bash-based CLI.

## Overview

The assistant supports multiple interaction modes—"friendly," "tutor," and "coder"—allowing dynamic personality control via system prompts. The UI is rendered in dark mode, and responses are formatted to handle code, tables, and inline markdown cleanly. Sessions are tracked in memory, and the app is suitable for lightweight experimentation or as a foundation for more advanced LLM applications.

## Features

* Flask back-end with RESTful `/chat` endpoint.
* OpenAI API integration (GPT-4.1-nano).
* Secure `.env` key handling and environment variable loading.
* Web UI supporting markdown, code blocks, and tables.
* Bash script interface for quick terminal queries.
* SQL-ready structure for future support of persistent session logging or user history

## Structure

The project consists of:

* `app.py`: Python Flask server with OpenAI API logic and rate limiting.
* `index.html`: Front-end UI with Markdown rendering and syntax highlighting
* `ask.sh`: Bash script for terminal-based interaction via cURL.

## Purpose

This project demonstrates the ability to integrate third-party LLM services into a secure, functional web app. It highlights practical skills in API handling, session management, front-end markup rendering, and interface design. It also reflects backend reliability concerns through rate limiting and secure credential management.

## License

© 2025 Cameron Marchese. All rights reserved. This project is shared for demonstration purposes only. Redistribution of API keys or hosted endpoints is prohibited.