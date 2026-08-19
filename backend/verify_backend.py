import os
import sys
import json
import logging

# Set PYTHONPATH to root directory
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("verify_backend")

def test_database():
    logger.info("--- Testing Database ---")
    try:
        from backend.services.database import create_session, get_session, add_message, get_session_history
        session_id = "test-session-123"
        
        # Clean up existing test session if any
        import sqlite3
        conn = sqlite3.connect("voice_agent.db")
        cursor = conn.cursor()
        cursor.execute("DELETE FROM messages WHERE session_id = ?", (session_id,))
        cursor.execute("DELETE FROM sessions WHERE session_id = ?", (session_id,))
        conn.commit()
        conn.close()
        
        # Test Session creation
        session = create_session(session_id, "emma", "free_chat")
        logger.info(f"Session created: {session}")
        
        # Test Retrieve session
        retrieved = get_session(session_id)
        assert retrieved is not None, "Failed to retrieve session"
        logger.info(f"Session retrieved successfully: {retrieved}")
        
        # Test Add Message
        msg = add_message(
            message_id="msg-1",
            session_id=session_id,
            role="user",
            content="Hello teacher!",
            grammar_corrections=[]
        )
        logger.info(f"Message added successfully: {msg}")
        
        history = get_session_history(session_id)
        assert len(history) == 1, "History length incorrect"
        logger.info(f"History retrieved: {history}")
        
        logger.info("Database tests: PASSED\n")
        return True
    except Exception as e:
        logger.error(f"Database tests failed: {e}")
        return False

def test_brain_llm():
    logger.info("--- Testing LLM Brain (Cloud Mode Mock / Actual) ---")
    try:
        from backend.services.brain import generate_tutor_response
        from backend.config import settings
        
        logger.info(f"Current Model Mode: {settings.MODEL_MODE}")
        
        # Check if keys are available
        has_groq = bool(settings.GROQ_API_KEY) and not settings.GROQ_API_KEY.startswith("your-")
        has_openai = bool(settings.OPENAI_API_KEY) and not settings.OPENAI_API_KEY.startswith("your-")
        logger.info(f"API Keys available: Groq={has_groq}, OpenAI={has_openai}")
        
        if settings.MODEL_MODE == "cloud" and not (has_groq or has_openai):
            logger.warning("Cloud mode active but no valid API keys found in env. Skipping LLM Brain API test.")
            return True
            
        # Mock history
        history = []
        user_message = "Yesterday I go to market and buyed apples."
        
        logger.info(f"Sending test student message: '{user_message}'")
        
        # Call brain tutor response
        result = generate_tutor_response(
            session_id="test-session-123",
            user_message=user_message,
            persona_id="emma",
            mode="free_chat",
            history=history
        )
        
        logger.info("Received Brain response:")
        logger.info(json.dumps(result, indent=2))
        
        assert "reply" in result, "Brain response missing 'reply'"
        assert "corrections" in result, "Brain response missing 'corrections'"
        
        # If cloud was active, check if corrections were found
        if settings.MODEL_MODE == "cloud" and (has_groq or has_openai):
            assert len(result["corrections"]) > 0, "Expected grammar corrections for 'I go to market and buyed apples'"
            logger.info("Brain LLM successfully detected and corrected grammar errors!")
            
        logger.info("Brain LLM tests: PASSED\n")
        return True
    except Exception as e:
        logger.error(f"Brain LLM tests failed: {e}")
        return False

def test_tts():
    logger.info("--- Testing TTS Speech Synthesis ---")
    try:
        from backend.services.tts import synthesize_speech
        from backend.config import settings
        
        has_openai = bool(settings.OPENAI_API_KEY) and not settings.OPENAI_API_KEY.startswith("your-")
        if settings.MODEL_MODE == "cloud" and not has_openai:
            logger.warning("Cloud mode active but no valid OPENAI_API_KEY found in env. Skipping TTS API test.")
            return True
            
        test_text = "Hello! Welcome to your English tutoring session."
        logger.info(f"Synthesizing test text: '{test_text}'")
        
        # Test TTS (either local or cloud)
        audio_bytes = synthesize_speech(test_text, voice_name="emma")
        
        logger.info(f"Generated audio size: {len(audio_bytes)} bytes")
        assert len(audio_bytes) > 0, "Generated empty audio bytes"
        
        logger.info("TTS tests: PASSED\n")
        return True
    except Exception as e:
        logger.error(f"TTS tests failed: {e}")
        return False

if __name__ == "__main__":
    logger.info("=== Running Backend Verification Test ===")
    
    db_ok = test_database()
    brain_ok = test_brain_llm()
    tts_ok = test_tts()
    
    if db_ok and brain_ok and tts_ok:
        logger.info("=== All Backend Modules Verified Successfully! ===")
        sys.exit(0)
    else:
        logger.error("=== Backend Module Verification Failed! ===")
        sys.exit(1)
