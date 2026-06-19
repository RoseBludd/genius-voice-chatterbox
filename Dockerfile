# Genius Voice Stack — Chatterbox + OmniVoice for Railway
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ffmpeg libsndfile1 build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir torch torchaudio --index-url https://download.pytorch.org/whl/cpu

RUN git clone --depth 1 https://github.com/travisvn/chatterbox-tts-api.git /tmp/cb \
    && cp -r /tmp/cb/app /tmp/cb/main.py /tmp/cb/requirements.txt /app/ \
    && pip install --no-cache-dir fastapi "uvicorn[standard]" python-dotenv python-multipart requests psutil pydub sse-starlette \
    && pip install --no-cache-dir git+https://github.com/travisvn/chatterbox-multilingual.git@exp \
    && rm -rf /tmp/cb

RUN mkdir -p /cache /voices /data/long_text_jobs
RUN curl -fsSL -o /app/voice-sample.mp3 "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3" || true

ENV PORT=4123
ENV HOST=0.0.0.0
ENV DEVICE=cpu
ENV MODEL_CACHE_DIR=/cache
ENV VOICE_LIBRARY_DIR=/voices
ENV VOICE_SAMPLE_PATH=/app/voice-sample.mp3

EXPOSE 4123
HEALTHCHECK --interval=30s --timeout=30s --start-period=600s --retries=3 \
  CMD curl -f http://localhost:4123/health || exit 1

CMD ["python", "main.py"]
