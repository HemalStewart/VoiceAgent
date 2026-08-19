# EnglishMind AI - Spoken English AI Tutor Platform

A high-accuracy, interactive spoken English learning platform built with **Next.js (App Router + TypeScript + Tailwind)** and a **Python FastAPI backend**.

The voice pipeline supports both **Cloud API Mode** (low latency, runs on any device) and **Local Offline Mode** (runs completely self-hosted with offline models).

---

## Architecture Pipeline

```
Student Speaks (Browser Audio Capture)
             │
             ▼
      Whisper ASR (STT)
             │
             ▼
   LLM Brain (Qwen/Llama/GPT) ────► (Generates Grammatical Corrections, CEFR feedback)
             │
             ▼
       Kokoro TTS (TTS)
             │
             ▼
     Student Hears Voice
```

---

## Tech Stack & Features

- **Frontend**: Next.js App Router, Tailwind CSS, Zustand, Lucide Icons, Canvas API (Realtime microphone waveform visualizer).
- **Backend API**: FastAPI (Python), Uvicorn.
- **Database**: SQLite3 (Local file-based database for session tracking, message history, and learning analytics).
- **Speech-to-Text (STT)**: local `faster-whisper` or cloud `OpenAI Whisper`.
- **LLM Brain**: local `Qwen-2.5` (via Ollama/Transformers) or cloud `Groq Llama-3.1` / `OpenAI GPT-4o-mini` with strict JSON schema outputs.
- **Text-to-Speech (TTS)**: local `Kokoro-82M` (very high-fidelity open-source speech synthesizer) or cloud `OpenAI TTS` / `ElevenLabs`.

---

## Setup Instructions

### 1. Configure Environment Variables

Rename `.env.example` to `.env` in the root folder and configure your API keys (e.g. for Groq or OpenAI):

```bash
cp .env.example .env
```

Edit the `.env` file to add your API keys:
```env
MODEL_MODE=cloud
OPENAI_API_KEY=your-openai-api-key-here
GROQ_API_KEY=your-groq-api-key-here
```

### 2. Launch the Application

We provide a custom script `start.sh` that launches both the Next.js frontend (port 3000) and the FastAPI backend (port 8000) simultaneously.

```bash
./start.sh
```

Open [http://localhost:3000](http://localhost:3000) in your browser to start talking to your tutor.

---

## Modes: Cloud vs. Local Offline

### Cloud Mode (Default & Low Latency)
Runs out of the box on any device (including lightweight Macbooks/CPU systems). Requires API keys in `.env`.

### Local Offline Mode (Self-Hosted)
To run everything locally without external API tokens, set `MODEL_MODE=local` in your `.env`.

> [!NOTE]
> Running models locally requires Python 3.10+ (to obtain precompiled wheels for `scipy` and `spacy`) and a GPU/Apple Silicon Mac for reasonable speeds.
>
> Install the extra ML dependencies inside the virtual environment:
> ```bash
> source backend/venv/bin/activate
> pip install -r backend/requirements-local.txt
> ```

---

## Developer Guide & Code Map

- [backend/app.py](file:///Users/lakminiinternational/VoiceAgent/backend/app.py): REST endpoints for processing speech, starting sessions, and fetching learning analytics.
- [backend/services/stt.py](file:///Users/lakminiinternational/VoiceAgent/backend/services/stt.py): Speech transcription controller.
- [backend/services/brain.py](file:///Users/lakminiinternational/VoiceAgent/backend/services/brain.py): System instructions for English tutors and structured JSON parser.
- [backend/services/tts.py](file:///Users/lakminiinternational/VoiceAgent/backend/services/tts.py): Voice synthesizer controller.
- [backend/services/database.py](file:///Users/lakminiinternational/VoiceAgent/backend/services/database.py): SQLite helper functions.
- [frontend/src/app/page.tsx](file:///Users/lakminiinternational/VoiceAgent/frontend/src/app/page.tsx): Main dashboard layout.
- [frontend/src/store/voiceStore.ts](file:///Users/lakminiinternational/VoiceAgent/frontend/src/store/voiceStore.ts): Zustand state store managing audio recordings, REST communications, and playback.
