import os
import uuid
import base64
import logging
from typing import Optional
from fastapi import FastAPI, UploadFile, File, Form, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

from backend.config import settings
from backend.services.database import create_session, get_session, get_session_history, add_message, get_analytics
from backend.services.stt import transcribe_audio
from backend.services.brain import generate_tutor_response
from backend.services.tts import synthesize_speech

# Configure Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger("app")

app = FastAPI(title="Spoken English AI Tutor API", version="1.0.0")

# Setup CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, restrict this to the frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Ensure temporary upload and audio cache directory exists
UPLOAD_DIR = "temp_uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# Expose upload directory statically
app.mount("/static", StaticFiles(directory=UPLOAD_DIR), name="static")

@app.get("/api/health")
def health_check():
    return {
        "status": "healthy",
        "mode": settings.MODEL_MODE,
        "local_models": {
            "whisper": settings.LOCAL_WHISPER_MODEL,
            "llm": settings.LOCAL_LLM_MODEL,
            "tts_voice": settings.LOCAL_TTS_VOICE
        }
    }

@app.post("/api/sessions")
def start_session(persona: str = Form("emma"), mode: str = Form("free_chat")):
    """
    Initializes a new learning session.
    """
    session_id = str(uuid.uuid4())
    session = create_session(session_id, persona, mode)
    logger.info(f"Created session {session_id} with persona {persona} and mode {mode}")
    return session

@app.get("/api/sessions/{session_id}/history")
def session_history(session_id: str):
    """
    Retrieves the conversation history for a session.
    """
    session = get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    history = get_session_history(session_id)
    return {
        "session": session,
        "history": history
    }

@app.post("/api/process-audio")
async def process_audio(
    session_id: str = Form(...),
    audio: UploadFile = File(...)
):
    """
    Core Voice Pipeline Endpoint:
    Receives user recorded speech -> Transcribes (STT) -> Generates response + corrections (LLM) -> Synthesizes reply voice (TTS).
    """
    # 1. Verify session exists
    session = get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
        
    persona = session["persona"]
    mode = session["mode"]
    
    # 2. Save user audio to file
    user_audio_filename = f"user_{session_id}_{uuid.uuid4().hex[:8]}.wav"
    user_audio_path = os.path.join(UPLOAD_DIR, user_audio_filename)
    
    try:
        with open(user_audio_path, "wb") as f:
            content = await audio.read()
            f.write(content)
        logger.info(f"Saved uploaded user audio to {user_audio_path}")
    except Exception as e:
        logger.error(f"Failed to save user audio file: {e}")
        raise HTTPException(status_code=500, detail="Failed to save audio file")
        
    # 3. Transcribe audio (STT)
    try:
        user_transcript = transcribe_audio(user_audio_path)
    except Exception as e:
        logger.error(f"STT transcription failed: {e}")
        raise HTTPException(status_code=500, detail=f"Speech-to-Text translation failed: {str(e)}")
        
    if not user_transcript:
        raise HTTPException(status_code=400, detail="Could not understand speech. Please speak clearly.")
        
    # 4. Fetch session history
    history = get_session_history(session_id)
    
    # 5. Generate LLM response, corrections, CEFR estimate (Brain)
    try:
        brain_response = generate_tutor_response(
            session_id=session_id,
            user_message=user_transcript,
            persona_id=persona,
            mode=mode,
            history=history
        )
    except Exception as e:
        logger.error(f"LLM Brain failed: {e}")
        raise HTTPException(status_code=500, detail=f"Tutor engine failed: {str(e)}")
        
    tutor_reply = brain_response.get("reply", "")
    corrections = brain_response.get("corrections", [])
    suggestions = brain_response.get("suggestions", [])
    pronunciation_targets = brain_response.get("pronunciation_targets", [])
    cefr_estimate = brain_response.get("cefr_estimate", "B1")
    
    # 6. Save user message with details to DB
    user_message_id = str(uuid.uuid4())
    add_message(
        message_id=user_message_id,
        session_id=session_id,
        role="user",
        content=user_transcript,
        audio_path=f"/static/{user_audio_filename}",
        grammar_corrections=corrections,
        suggestions=suggestions,
        cefr_estimate=cefr_estimate
    )
    
    # 7. Synthesize tutor speech (TTS)
    tutor_audio_base64 = ""
    tutor_audio_filename = f"tutor_{session_id}_{uuid.uuid4().hex[:8]}.wav"
    tutor_audio_path = os.path.join(UPLOAD_DIR, tutor_audio_filename)
    
    try:
        # Load tutor speech bytes
        audio_bytes = synthesize_speech(tutor_reply, voice_name=persona)
        
        if audio_bytes and len(audio_bytes) > 0:
            # Save to static files for references/debugging
            with open(tutor_audio_path, "wb") as f:
                f.write(audio_bytes)
                
            # Base64 encode for direct frontend playback (reduces HTTP requests)
            tutor_audio_base64 = base64.b64encode(audio_bytes).decode("utf-8")
            logger.info(f"Saved synthesized tutor audio to {tutor_audio_path}")
        else:
            logger.info("No audio bytes generated by TTS service. Skipping file save.")
    except Exception as e:
        logger.error(f"TTS synthesis failed: {e}")
        # We don't block the conversation if TTS fails, just continue without audio
        
    # 8. Save tutor response to DB
    tutor_message_id = str(uuid.uuid4())
    add_message(
        message_id=tutor_message_id,
        session_id=session_id,
        role="assistant",
        content=tutor_reply,
        audio_path=f"/static/{tutor_audio_filename}" if os.path.exists(tutor_audio_path) else None,
        pronunciation_targets=pronunciation_targets
    )
    
    return {
        "user_transcript": user_transcript,
        "tutor_reply": tutor_reply,
        "corrections": corrections,
        "suggestions": suggestions,
        "pronunciation_targets": pronunciation_targets,
        "cefr_estimate": cefr_estimate,
        "tutor_audio_base64": tutor_audio_base64,
        "tutor_audio_url": f"/static/{tutor_audio_filename}" if os.path.exists(tutor_audio_path) else None
    }

@app.post("/api/process-text")
def process_text(
    session_id: str = Form(...),
    text: str = Form(...)
):
    """
    Text-only Pipeline Endpoint (100% Free):
    Receives user transcribed text -> Generates response + corrections (LLM Qwen) -> Returns text details.
    """
    session = get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
        
    persona = session["persona"]
    mode = session["mode"]
    history = get_session_history(session_id)
    
    try:
        brain_response = generate_tutor_response(
            session_id=session_id,
            user_message=text,
            persona_id=persona,
            mode=mode,
            history=history
        )
    except Exception as e:
        logger.error(f"LLM Brain failed: {e}")
        raise HTTPException(status_code=500, detail=f"Tutor engine failed: {str(e)}")
        
    tutor_reply = brain_response.get("reply", "")
    corrections = brain_response.get("corrections", [])
    suggestions = brain_response.get("suggestions", [])
    pronunciation_targets = brain_response.get("pronunciation_targets", [])
    cefr_estimate = brain_response.get("cefr_estimate", "B1")
    
    # Save user message to DB (no audio_path since text-only)
    user_message_id = str(uuid.uuid4())
    add_message(
        message_id=user_message_id,
        session_id=session_id,
        role="user",
        content=text,
        audio_path=None,
        grammar_corrections=corrections,
        suggestions=suggestions,
        cefr_estimate=cefr_estimate
    )
    
    # Save tutor response to DB (no audio_path)
    tutor_message_id = str(uuid.uuid4())
    add_message(
        message_id=tutor_message_id,
        session_id=session_id,
        role="assistant",
        content=tutor_reply,
        audio_path=None,
        pronunciation_targets=pronunciation_targets
    )
    
    return {
        "user_transcript": text,
        "tutor_reply": tutor_reply,
        "corrections": corrections,
        "suggestions": suggestions,
        "pronunciation_targets": pronunciation_targets,
        "cefr_estimate": cefr_estimate,
        "tutor_audio_base64": "",
        "tutor_audio_url": None
    }

@app.get("/api/analytics")
def get_user_analytics():
    """
    Retrieves global stats and grammar trends.
    """
    try:
        return get_analytics()
    except Exception as e:
        logger.error(f"Failed to load analytics: {e}")
        raise HTTPException(status_code=500, detail="Failed to calculate analytics")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("backend.app:app", host=settings.HOST, port=settings.PORT, reload=True)
