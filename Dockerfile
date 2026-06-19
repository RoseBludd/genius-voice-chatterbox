# Chatterbox TTS for Railway CPU — pinned deps (fixes numpy/scipy + torch ABI crashes)
# Official travisvn/chatterbox-tts-api:latest-cpu fails at import:
#   ValueError: All ufuncs must have type numpy.ufunc (numpy/scipy mismatch)
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ffmpeg libsndfile1 build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# PyTorch CPU — matched pair (avoids aoti_torch_abi_version crash)
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir \
       torch==2.5.1 torchaudio==2.5.1 \
       --index-url https://download.pytorch.org/whl/cpu

# Pin numpy/scipy BEFORE librosa/perth/chatterbox (fixes sph_legendre_p ufunc crash)
RUN pip install --no-cache-dir numpy==1.26.4 scipy==1.11.4

RUN git clone --depth 1 --branch stable https://github.com/travisvn/chatterbox-tts-api.git /src \
    && cp -r /src/app /app/app \
    && cp /src/main.py /app/ \
    && pip install --no-cache-dir \
       fastapi "uvicorn[standard]" python-dotenv python-multipart requests psutil \
       pydantic pydub sse-starlette resemble-perth librosa==0.10.2 \
    && pip install --no-cache-dir --no-deps \
       "chatterbox-tts @ git+https://github.com/resemble-ai/chatterbox.git@v0.1.2" \
    && rm -rf /src

RUN python -c "\
import numpy, scipy, torch, torchaudio; \
from chatterbox.tts import ChatterboxTTS; \
print('ok', numpy.__version__, scipy.__version__, torch.__version__)"

RUN curl -fsSL -o /app/voice-sample.mp3 \
    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3" || true
RUN mkdir -p /cache /voices /data/long_text_jobs

ENV PORT=4123
ENV HOST=0.0.0.0
ENV DEVICE=cpu
ENV MODEL_CACHE_DIR=/cache
ENV VOICE_LIBRARY_DIR=/voices
ENV VOICE_SAMPLE_PATH=/app/voice-sample.mp3
ENV EXAGGERATION=0.5
ENV CFG_WEIGHT=0.5
ENV TEMPERATURE=0.7
ENV MAX_CHUNK_LENGTH=200
ENV MAX_TOTAL_LENGTH=2000
ENV ENABLE_MEMORY_MONITORING=true

EXPOSE 4123
HEALTHCHECK --interval=30s --timeout=30s --start-period=600s --retries=5 \
  CMD curl -f http://localhost:4123/health || exit 1

CMD ["python", "main.py"]
