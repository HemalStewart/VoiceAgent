import os
import logging
from backend.config import settings

logger = logging.getLogger("stt")

# Lazy-loaded local Whisper model to save resources if in cloud mode
_local_whisper_model = None

def get_local_whisper_model():
    global _local_whisper_model
    if _local_whisper_model is None:
        logger.info("Initializing local Whisper model...")
        try:
            from faster_whisper import WhisperModel
            # Using CPU for faster-whisper on Mac since GPU is CUDA-only for faster-whisper
            model_size = settings.LOCAL_WHISPER_MODEL
            logger.info(f"Loading local Whisper model: {model_size} (CPU, float32)")
            _local_whisper_model = WhisperModel(model_size, device="cpu", compute_type="float32")
            logger.info("Local Whisper model loaded successfully.")
        except Exception as e:
            logger.error(f"Failed to load local Whisper model: {e}")
            raise e
    return _local_whisper_model

def transcribe_audio(audio_path: str) -> str:
    """
    Transcribes audio file to text. Supports local faster-whisper or cloud OpenAI Whisper.
    """
    if not os.path.exists(audio_path):
        raise FileNotFoundError(f"Audio file not found: {audio_path}")
        
    if settings.MODEL_MODE == "local":
        logger.info(f"Transcribing {audio_path} locally...")
        try:
            model = get_local_whisper_model()
            segments, info = model.transcribe(audio_path, beam_size=5)
            transcript_text = " ".join([segment.text for segment in segments]).strip()
            logger.info(f"Local transcription result: {transcript_text}")
            return transcript_text
        except Exception as e:
            logger.error(f"Local transcription failed: {e}. Falling back to cloud STT.")
            # Fall back to cloud STT if key is present
            if not settings.OPENAI_API_KEY:
                raise RuntimeError(f"Local transcription failed and no OPENAI_API_KEY for cloud fallback: {e}")
            
    # Cloud mode (or fallback)
    if settings.GROQ_API_KEY:
        logger.info(f"Transcribing {audio_path} via Groq Whisper API...")
        try:
            from groq import Groq
            client = Groq(api_key=settings.GROQ_API_KEY)
            with open(audio_path, "rb") as audio_file:
                transcript = client.audio.transcriptions.create(
                    model="whisper-large-v3-turbo",
                    file=audio_file
                )
            logger.info(f"Groq transcription result: {transcript.text}")
            return transcript.text
        except Exception as e:
            logger.error(f"Groq transcription failed: {e}. Trying OpenAI fallback...")

    logger.info(f"Transcribing {audio_path} via OpenAI API...")
    if not settings.OPENAI_API_KEY:
        raise ValueError("Neither GROQ_API_KEY nor OPENAI_API_KEY is set. Cannot transcribe via cloud API.")
        
    try:
        from openai import OpenAI
        client = OpenAI(api_key=settings.OPENAI_API_KEY)
        with open(audio_path, "rb") as audio_file:
            transcript = client.audio.transcriptions.create(
                model="whisper-1",
                file=audio_file
            )
        logger.info(f"Cloud transcription result: {transcript.text}")
        return transcript.text
    except Exception as e:
        logger.error(f"Cloud transcription failed: {e}")
        raise e
