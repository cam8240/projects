from flask import Flask, request, jsonify
import openai
import os
from dotenv import load_dotenv
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_cors import CORS

# Load environment variables from key.env
load_dotenv("key.env")
client = openai.OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# Flask app setup
app = Flask(__name__)
CORS(app)
limiter = Limiter(get_remote_address, app=app, default_limits=["20 per minute"])

# In-memory chat history for simplicity (you could use Redis for real apps)
session_history = {}

# Prompt modes
prompt_modes = {
    "friendly": "You are a friendly and casual assistant.",
    "tutor": "You are a professional tutor who explains clearly.",
    "coder": "You are a helpful coding assistant who writes Python code."
}

@app.route("/chat", methods=["POST"])
@limiter.limit("10/minute")  # individual endpoint rate limiting
def chat():
    try:
        data = request.get_json()
        user_message = data.get("message", "").strip()
        mode = data.get("mode", "friendly").lower()
        session_id = data.get("session_id", "default")  # simple session management

        if not user_message:
            return jsonify({"error": "Empty message"}), 400

        # Choose system prompt based on mode
        system_prompt = prompt_modes.get(mode, prompt_modes["friendly"])

        # Get or create message history
        if session_id not in session_history:
            session_history[session_id] = [{"role": "system", "content": system_prompt}]
        session_history[session_id].append({"role": "user", "content": user_message})

        # Call OpenAI
        response = client.chat.completions.create(
            model="gpt-4.1-nano",  # switch to available model as needed
            messages=session_history[session_id]
        )

        reply = response.choices[0].message.content
        session_history[session_id].append({"role": "assistant", "content": reply})

        return jsonify({"reply": reply})

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0")
