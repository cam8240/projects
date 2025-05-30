from flask import Flask, request, jsonify
import openai
import os
from dotenv import load_dotenv
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

# Load environment variables from key.env
load_dotenv("key.env")
client = openai.OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# Flask app setup
app = Flask(__name__)
CORS(app)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///chat.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)
limiter = Limiter(get_remote_address, app=app, default_limits=["20 per minute"])

# Database model
class ChatLog(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    session_id = db.Column(db.String(100))
    role = db.Column(db.String(20))
    message = db.Column(db.Text)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

# In-memory chat history for simplicity
session_history = {}

# Prompt modes
prompt_modes = {
    "friendly": "You are a friendly and casual assistant.",
    "tutor": "You are a professional tutor who explains clearly.",
    "coder": "You are a helpful coding assistant who writes Python code."
}

@app.route("/chat", methods=["POST"])
@limiter.limit("10/minute")
def chat():
    try:
        data = request.get_json()
        user_message = data.get("message", "").strip()
        mode = data.get("mode", "friendly").lower()
        session_id = data.get("session_id", "default")

        if not user_message:
            return jsonify({"error": "Empty message"}), 400

        # Choose system prompt
        system_prompt = prompt_modes.get(mode, prompt_modes["friendly"])

        # Get or create session history
        if session_id not in session_history:
            session_history[session_id] = [{"role": "system", "content": system_prompt}]
            db.session.add(ChatLog(session_id=session_id, role="system", message=system_prompt))

        session_history[session_id].append({"role": "user", "content": user_message})
        db.session.add(ChatLog(session_id=session_id, role="user", message=user_message))

        # Call OpenAI API
        response = client.chat.completions.create(
            model="gpt-4.1-nano",
            messages=session_history[session_id]
        )
        print(response)
        reply = response.choices[0].message.content
        session_history[session_id].append({"role": "assistant", "content": reply})
        db.session.add(ChatLog(session_id=session_id, role="assistant", message=reply))

        db.session.commit()
        return jsonify({"reply": reply})

    except Exception as e:
        import traceback
        traceback.print_exc()
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0")
