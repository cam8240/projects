# GPT Frontend

This Vue 3 frontend provides two interactive tools:

## 1. Interview Coach (`/coach`)

A real-time speaking practice interface.

### Features

* **Live Microphone Input**
  Captures audio and streams in 6-second chunks to the backend for transcription.

* **WebSocket or REST Compatible**
  Can work with either fetch-based or socket-based backends.

* **Transcript Panel**
  Displays live transcribed text.

* **Suggestions Panel**
  Static (or dynamic) list of speaking tips shown on the left.

* **Start/Stop Controls**
  Toggles audio streaming session with clear visual state.

---

## 2. Chat Assistant (`/`)

A text-based assistant with multiple personalities.

### Features

* **Chat Modes**
  Choose between `friendly`, `tutor`, or `coder` system prompts.

* **Message Persistence**
  Chat history is stored in localStorage and restored on reload.

* **Markdown Rendering**
  Assistant messages support code formatting and inline copy buttons.

* **Error Handling & Retry**
  Gracefully handles failed requests with auto-retry.

* **Auto-Growing Input**
  Textarea expands as the user types.

---

## Tech Stack

* Vue 3 Composition API
* `marked` for Markdown rendering
* `highlight.js` for syntax highlighting
* `socket.io-client` for WebSocket integration (optional)
* Basic CSS for layout and responsiveness

---

## Usage

```bash
npm install
npm run dev
```

Make sure your backend is running at `http://localhost:5000`.

---

This frontend is modular: each feature (chat and coach) can function independently or together depending on routing setup.
