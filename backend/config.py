import os
from dotenv import load_dotenv

# Load .env file if it exists
load_dotenv()

class Settings:
    # App General
    PORT: int = int(os.getenv("PORT", "8000"))
    HOST: str = os.getenv("HOST", "0.0.0.0")
    
    # Model Operation Mode: 'cloud' (default) or 'local'
    MODEL_MODE: str = os.getenv("MODEL_MODE", "cloud").lower()
    
    # Cloud API Keys
    OPENAI_API_KEY: str = "" if os.getenv("OPENAI_API_KEY", "").startswith("your-") else os.getenv("OPENAI_API_KEY", "")
    GROQ_API_KEY: str = "" if os.getenv("GROQ_API_KEY", "").startswith("your-") else os.getenv("GROQ_API_KEY", "")
    ELEVENLABS_API_KEY: str = "" if os.getenv("ELEVENLABS_API_KEY", "").startswith("your-") else os.getenv("ELEVENLABS_API_KEY", "")
    
    # Local Model Configurations
    LOCAL_WHISPER_MODEL: str = os.getenv("LOCAL_WHISPER_MODEL", "base")
    LOCAL_LLM_MODEL: str = os.getenv("LOCAL_LLM_MODEL", "Qwen/Qwen2.5-1.5B-Instruct")
    LOCAL_TTS_VOICE: str = os.getenv("LOCAL_TTS_VOICE", "af_bella")
    
    # Database Settings
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./voice_agent.db")

settings = Settings()
