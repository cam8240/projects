import eventlet
eventlet.monkey_patch()

from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_socketio import SocketIO
from dotenv import load_dotenv
from whisper_handler import transcribe_audio_chunk
from datetime import datetime
import requests
import openai
import os

# --- ENV & API Setup ---
load_dotenv(".env")
client = openai.OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

app = Flask(__name__)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")
limiter = Limiter(get_remote_address, app=app, default_limits=["20 per minute"])

# --- Database Config ---
app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv("DATABASE_URL")
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
db = SQLAlchemy(app)

# --- Models ---
class ChatLog(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    session_id = db.Column(db.String(100))
    role = db.Column(db.String(20))
    message = db.Column(db.Text)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

# --- Chat Mode Prompts ---
session_history = {}
prompt_modes = {
    "friendly": "You are a friendly and casual assistant.",
    "tutor": "You are a professional tutor who explains clearly.",
    "coder": "You are a helpful coding assistant who writes Python code."
}

def analyze_with_go_service(text):
    try:
        res = requests.post("http://analyzer:6000/analyze", json={"text": text}, timeout=2)
        return res.json() if res.status_code == 200 else {"error": f"Go service error: {res.status_code}"}
    except Exception as e:
        return {"error": str(e)}

# --- REST ENDPOINTS ---
@app.route("/chat", methods=["POST"])
@limiter.limit("5 per minute")
def chat():
    try:
        data = request.get_json()
        user_message = data.get("message", "").strip()
        mode = data.get("mode", "friendly").lower()
        session_id = data.get("session_id", "default")

        if not user_message:
            return jsonify({"error": "Empty message"}), 400

        if len(user_message) > 1000:
            return jsonify({"error": "Message too long (max 1000 characters)."}), 400

        system_prompt = prompt_modes.get(mode, prompt_modes["friendly"])

        if session_id not in session_history:
            session_history[session_id] = [{"role": "system", "content": system_prompt}]
            db.session.add(ChatLog(session_id=session_id, role="system", message=system_prompt))

        session_history[session_id].append({"role": "user", "content": user_message})
        db.session.add(ChatLog(session_id=session_id, role="user", message=user_message))

        go_analysis = analyze_with_go_service(user_message)
        print("Go analysis:", go_analysis)

        response = client.chat.completions.create(
            model="gpt-4.1-nano",
            messages=session_history[session_id]
        )
        reply = response.choices[0].message.content
        session_history[session_id].append({"role": "assistant", "content": reply})
        db.session.add(ChatLog(session_id=session_id, role="assistant", message=reply))

        db.session.commit()
        return jsonify({"reply": reply})
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

@app.route("/history/<session_id>", methods=["GET"])
def get_history(session_id):
    try:
        messages = ChatLog.query.filter_by(session_id=session_id).order_by(ChatLog.timestamp.asc()).all()
        history = [
            {
                "role": msg.role,
                "message": msg.message,
                "timestamp": msg.timestamp.isoformat()
            }
            for msg in messages
        ]
        return jsonify({"session_id": session_id, "history": history})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/interview/stream", methods=["POST"])
def handle_audio_stream():
    try:
        raw_audio = request.data
        result = transcribe_audio_chunk(raw_audio)
        return jsonify({"transcript": result})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# --- SOCKET.IO EVENTS ---
@socketio.on("connect")
def handle_connect():
    print("WebSocket client connected")

@socketio.on("disconnect")
def handle_disconnect():
    print("WebSocket client disconnected")

@socketio.on("audio_chunk")
def handle_audio_chunk(data):
    try:
        result = transcribe_audio_chunk(data)
        socketio.emit("transcript", {"text": result})
    except Exception as e:
        socketio.emit("error", {"error": str(e)})

# --- APP START ---
if __name__ == "__main__":
    with app.app_context():
        db.create_all()
    socketio.run(app, host="0.0.0.0", port=5000, debug=True)
