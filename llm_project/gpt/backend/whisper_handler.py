import subprocess
import uuid
import os
from pathlib import Path

# Path to the whisper model inside the container
DEFAULT_MODEL = "whisper.cpp/models/ggml-base.en.bin"

def transcribe_audio_chunk(raw_audio: bytes,
                           model_path: str = DEFAULT_MODEL,
                           temp_dir: str = "/tmp") -> str:
    """
    Save the incoming audio chunk (webm), convert it to WAV, run whisper.cpp,
    and return the transcribed text or error message.
    """
    uid = str(uuid.uuid4())
    webm_path = Path(temp_dir) / f"{uid}.webm"
    wav_path  = Path(temp_dir) / f"{uid}.wav"
    txt_path  = Path(temp_dir) / f"{uid}.txt"

    print(f"[DEBUG] Saving audio to: {webm_path}")

    try:
        # 1. Save raw blob to temp .webm file
        webm_path.write_bytes(raw_audio)

        if webm_path.stat().st_size < 2048:
            return "Error: audio chunk too small or corrupt."

        # 2. Convert .webm to 16 kHz mono .wav using FFmpeg
        print(f"[DEBUG] Running ffmpeg: {webm_path} -> {wav_path}")
        ff = subprocess.run(
            ["ffmpeg", "-loglevel", "error", "-y",
             "-f", "webm",
             "-i", str(webm_path),
             "-ar", "16000", "-ac", "1",
             str(wav_path)],
            capture_output=True,
        )
        if ff.returncode != 0:
            print(f"[FFMPEG ERROR]\n{ff.stderr.decode()}")
            return f"FFmpeg error:\n{ff.stderr.decode().strip()}"

        # 3. Run whisper-cli transcription
        print(f"[DEBUG] Running whisper-cli on: {wav_path}")
        wc = subprocess.run(
            ["./whisper.cpp/build/bin/whisper-cli",
             "-m", model_path,
             "-f", str(wav_path),
             "-otxt",  # output .txt
             "-of", str(txt_path.with_suffix(""))],
            capture_output=True,
        )
        if wc.returncode != 0:
            print(f"[WHISPER ERROR]\n{wc.stderr.decode()}")
            return f"Whisper error:\n{wc.stderr.decode().strip()}"

        if not txt_path.exists():
            print("[DEBUG] No transcript created.")
            return "Whisper error: transcript file not created."

        print(f"[DEBUG] Transcript created at: {txt_path}")
        return txt_path.read_text().strip()

    except Exception as exc:
        print(f"[GENERAL ERROR] {exc}")
        return f"General error: {exc}"

    finally:
        # Optional: clean up after success or failure
        for p in (webm_path, wav_path, txt_path):
            try:
                p.unlink(missing_ok=True)
            except Exception:
                pass
