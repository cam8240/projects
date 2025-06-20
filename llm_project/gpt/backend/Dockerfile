FROM python:3.11-slim

WORKDIR /app

# --- Install system dependencies ---
RUN apt-get update && apt-get install -y \
    ffmpeg git build-essential cmake wget \
 && rm -rf /var/lib/apt/lists/*

# --- Install Python dependencies ---
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# --- Clone and build whisper.cpp ---
RUN git clone https://github.com/ggerganov/whisper.cpp.git \
 && cd whisper.cpp && make -j

# --- Download the model (optional but useful for Docker image) ---
# You can change the model to base.en or medium.en if needed
RUN wget -O /app/whisper.cpp/models/ggml-tiny.en.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin
RUN wget -O /app/whisper.cpp/models/ggml-base.en.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin

# --- Copy the rest of your app ---
COPY . .

# --- Add whisper-cli to PATH (optional but useful) ---
ENV PATH="/app/whisper.cpp/build/bin:$PATH"

# --- Expose Flask app port ---
EXPOSE 5000

CMD ["python", "app.py"]
