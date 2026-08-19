import os
import io
import logging
from typing import Optional
from backend.config import settings

logger = logging.getLogger("tts")

# Cache pipelines by language code ('a' for American English, 'b' for British English)
_local_pipelines = {}

def get_local_tts_pipeline(lang_code: str):
    global _local_pipelines
    if lang_code not in _local_pipelines:
        logger.info(f"Initializing local Kokoro TTS pipeline for lang_code: '{lang_code}'...")
        try:
            from kokoro import KPipeline
            _local_pipelines[lang_code] = KPipeline(lang_code=lang_code)
            logger.info(f"Local Kokoro TTS pipeline for '{lang_code}' initialized successfully.")
        except Exception as e:
            logger.error(f"Failed to load local Kokoro TTS pipeline for '{lang_code}': {e}")
            raise e
    return _local_pipelines[lang_code]

def synthesize_speech(text: str, voice_name: Optional[str] = None) -> bytes:
    """
    Synthesizes speech from text. Supports local Kokoro TTS or cloud OpenAI/ElevenLabs TTS.
    Returns wav/mp3 audio bytes.
    """
    selected_voice = voice_name or settings.LOCAL_TTS_VOICE
    
    # Map frontend user-friendly personas to exact Kokoro voice files and language codes
    voice_mapping = {
        "emma": ("bf_emma", "b"),
        "alex": ("am_adam", "a"),
        "sophia": ("af_bella", "a")
    }
    
    voice_key = selected_voice.lower()
    if voice_key in voice_mapping:
        kokoro_voice, lang_code = voice_mapping[voice_key]
    else:
        kokoro_voice = selected_voice
        # Deduce language code from filename prefix (e.g. bf_isabella -> b, af_bella -> a)
        lang_code = 'b' if selected_voice.lower().startswith('b') else 'a'
        
    if settings.MODEL_MODE == "local":
        logger.info(f"Synthesizing speech locally using Kokoro with voice: {kokoro_voice} (lang: {lang_code})...")
        try:
            pipeline = get_local_tts_pipeline(lang_code)
            import numpy as np
            import soundfile as sf
            
            # Generate audio chunks
            generator = pipeline(text, voice=kokoro_voice, speed=1.0, split_pattern=r'\n+')
            audio_segments = []
            
            for gs, ps, audio in generator:
                if audio is not None and len(audio) > 0:
                    audio_segments.append(audio)
            
            if audio_segments:
                # Kokoro synthesizes at 24000Hz sampling rate
                full_audio = np.concatenate(audio_segments)
                buffer = io.BytesIO()
                sf.write(buffer, full_audio, 24000, format='WAV')
                logger.info("Local speech synthesis completed successfully.")
                return buffer.getvalue()
            else:
                raise RuntimeError("Kokoro generated empty audio segments.")
                
        except Exception as e:
            logger.error(f"Local TTS failed: {e}. Falling back to cloud TTS.")
            if not settings.OPENAI_API_KEY:
                raise RuntimeError(f"Local TTS failed and no OPENAI_API_KEY for cloud fallback: {e}")

    # Cloud mode (or fallback)
    logger.info("Synthesizing speech via OpenAI TTS...")
    if not settings.OPENAI_API_KEY:
        logger.warning("OPENAI_API_KEY is not set. Skipping cloud speech synthesis (frontend will use browser TTS).")
        return bytes()
        
    try:
        from openai import OpenAI
        client = OpenAI(api_key=settings.OPENAI_API_KEY)
        
        # Map selected tutor voice to standard OpenAI voices
        # Emma (British) -> nova/shimmer, Alex (American) -> alloy/onyx, Sophia -> fable
        openai_voice = "nova"
        lower_voice = selected_voice.lower()
        if "alex" in lower_voice or "am_" in lower_voice:
            openai_voice = "alloy"
        elif "sophia" in lower_voice:
            openai_voice = "fable"
            
        response = client.audio.speech.create(
            model="tts-1",
            voice=openai_voice,
            input=text
        )
        logger.info("Cloud speech synthesis completed successfully.")
        return response.content
    except Exception as e:
        logger.error(f"Cloud TTS failed: {e}. Skipping audio generation.")
        return bytes()
