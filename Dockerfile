# Chatterbox TTS API for Railway (official layout from travisvn/chatterbox-tts-api)
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    git wget curl build-essential ffmpeg libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir torch torchaudio --index-url https://download.pytorch.org/whl/cpu

RUN git clone --depth 1 https://github.com/travisvn/chatterbox-tts-api.git /src \
    && cp -r /src/app /app/app \
    && cp /src/main.py /src/requirements.txt /app/ \
    && pip install --no-cache-dir fastapi "uvicorn[standard]" python-dotenv python-multipart requests psutil pydub sse-starlette \
    && pip install --no-cache-dir git+https://github.com/travisvn/chatterbox-multilingual.git@exp \
    && rm -rf /src

RUN curl -fsSL -o /app/voice-sample.mp3 "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3" || true
RUN mkdir -p /cache /voices /data/long_text_jobs

ENV PORT=4123
ENV HOST=0.0.0.0
ENV DEVICE=cpu
ENV MODEL_CACHE_DIR=/cache
ENV VOICE_LIBRARY_DIR=/voices
ENV VOICE_SAMPLE_PATH=/app/voice-sample.mp3
ENV EXAGGERATION=0.5
ENV CFG_WEIGHT=0.5
ENV TEMPERATURE=0.8
ENV MAX_CHUNK_LENGTH=280

EXPOSE 4123
HEALTHCHECK --interval=30s --timeout=30s --start-period=600s --retries=5 \
  CMD curl -f http://localhost:4123/health || exit 1

CMD ["python", "main.py"]
