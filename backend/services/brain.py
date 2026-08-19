import os
import json
import logging
from typing import List, Dict, Any, Tuple
from backend.config import settings

logger = logging.getLogger("brain")

# Lazy-loaded local Hugging Face LLM model to save resources if not in local mode
_local_llm_pipeline = None

def get_local_llm_pipeline():
    global _local_llm_pipeline
    if _local_llm_pipeline is None:
        logger.info("Initializing local Qwen/Llama LLM model using Hugging Face transformers...")
        try:
            import torch
            from transformers import pipeline, AutoModelForCausalLM, AutoTokenizer
            
            model_id = settings.LOCAL_LLM_MODEL
            logger.info(f"Loading local LLM model: {model_id}...")
            
            # Detect device (Apple Silicon MPS vs CPU)
            device = "cpu"
            if torch.backends.mps.is_available():
                device = "mps"
            elif torch.cuda.is_available():
                device = "cuda"
            
            logger.info(f"Using device for LLM: {device}")
            
            tokenizer = AutoTokenizer.from_pretrained(model_id)
            model = AutoModelForCausalLM.from_pretrained(
                model_id,
                torch_dtype=torch.float32 if device == "cpu" else torch.float16,
                low_cpu_mem_usage=True
            )
            
            _local_llm_pipeline = pipeline(
                "text-generation",
                model=model,
                tokenizer=tokenizer,
                device=device,
                max_new_tokens=512,
                temperature=0.7
            )
            logger.info("Local LLM model loaded successfully.")
        except Exception as e:
            logger.error(f"Failed to load local LLM model: {e}")
            raise e
    return _local_llm_pipeline

PERSONA_PROMPTS = {
    "emma": {
        "name": "Emma",
        "description": "Friendly British Tutor. Speaks with Received Pronunciation (RP). Focuses on daily conversational vocabulary, polite expressions, and correct British phrasing.",
        "prompt": "You are Emma, a friendly and encouraging British English teacher. Speak with a warm, polite British tone."
    },
    "alex": {
        "name": "Alex",
        "description": "Energetic American Coach. Speaks with standard American accent. Focuses on slang, idioms, casual phrasing, and helping the student speak naturally.",
        "prompt": "You are Alex, an energetic and enthusiastic American English coach. Speak with a lively, casual, and highly encouraging American tone."
    },
    "sophia": {
        "name": "Sophia",
        "description": "Patient Business English Instructor. Focuses on formal vocabulary, professional emails, presentations, meetings, and business correspondence.",
        "prompt": "You are Sophia, a patient and professional Business English teacher. Focus on formal terminology, interviews, negotiation language, and career-oriented English."
    }
}

SYSTEM_INSTRUCTION = """
You are a highly advanced AI Spoken English Tutor. The user is a non-native English learner. 
Your goal is to converse with them, correct their errors, evaluate their progress, and teach them natural English phrasing.

You MUST respond strictly in valid JSON format. Do not write any markdown outside the JSON block. Do not include markdown code block formatting (e.g. ```json ... ```) in your output, just the raw JSON text.

Your JSON response must contain exactly the following keys:
1. "reply": The conversational response to the user. Keep it natural, conversational, friendly, and under 3-4 sentences. Keep the vocabulary appropriate for their estimated level.
2. "corrections": A list of spelling, grammar, or phrasing corrections. Empty if the user made no errors. Each correction must be a JSON object with keys:
    - "original": the exact sentence/phrase the user said.
    - "corrected": the grammatically correct version of that sentence/phrase.
    - "explanation": a concise explanation of why the correction is needed and the rule behind it.
3. "suggestions": A list of 1-2 alternative, more natural or advanced ways to express what the user meant (e.g., idiomatic phrasing, better vocabulary).
4. "pronunciation_targets": A list of 1-3 challenging words from your "reply" that the user might struggle to pronounce, which they should practice.
5. "cefr_estimate": Your estimate of the student's current English proficiency level in this turn (A1, A2, B1, B2, C1, or C2).
6. "topics": A list of 1-3 key vocabulary words or concepts covered in this turn.

Example JSON output:
{
  "reply": "That sounds like a wonderful plan! What kind of books do you enjoy reading the most?",
  "corrections": [
    {
      "original": "Yesterday I go to bookstore and buyed some books.",
      "corrected": "Yesterday I went to a bookstore and bought some books.",
      "explanation": "Use 'went' (past simple of 'go') and 'bought' (past simple of 'buy') for actions that completed in the past. Also add the article 'a' before bookstore."
    }
  ],
  "suggestions": [
    "Yesterday I visited a bookshop and picked up a few books.",
    "I dropped by a bookstore yesterday to buy some new reads."
  ],
  "pronunciation_targets": ["wonderful", "reading", "enjoy"],
  "cefr_estimate": "B1",
  "topics": ["Simple Past Tense", "Book Genres"]
}
"""

def generate_tutor_response(
    session_id: str,
    user_message: str,
    persona_id: str,
    mode: str,
    history: List[Dict[str, Any]]
) -> Dict[str, Any]:
    """
    Queries the LLM (local or cloud) using structured prompt engineering to get conversational responses + grammar corrections.
    """
    persona = PERSONA_PROMPTS.get(persona_id.lower(), PERSONA_PROMPTS["emma"])
    
    # Format conversation history for prompt
    formatted_history = []
    for msg in history[-8:]:  # Limit to last 8 messages for context
        role_label = "Student" if msg["role"] == "user" else "Tutor"
        formatted_history.append(f"{role_label}: {msg['content']}")
        
    history_str = "\n".join(formatted_history)
    
    # Construct complete prompt
    prompt = f"""{SYSTEM_INSTRUCTION}

Tutor Persona: {persona['prompt']}
Lesson Mode: {mode}

Conversation History:
{history_str}
Student: {user_message}
Tutor (JSON):"""

    # 1. Cloud Mode (Default/Fallback)
    if settings.MODEL_MODE == "cloud":
        # Check Groq first (extremely fast, high rate limits, has free Qwen 3)
        if settings.GROQ_API_KEY:
            logger.info("Generating response via Groq API (groq/compound)...")
            groq_models = ["groq/compound", "groq/compound-mini"]
            from groq import Groq
            client = Groq(api_key=settings.GROQ_API_KEY)
            for g_model in groq_models:
                try:
                    chat_completion = client.chat.completions.create(
                        messages=[
                            {"role": "system", "content": SYSTEM_INSTRUCTION},
                            {"role": "user", "content": f"Persona: {persona['prompt']}\nMode: {mode}\nHistory:\n{history_str}\nStudent: {user_message}"}
                        ],
                        model=g_model,
                        temperature=0.7,
                        response_format={"type": "json_object"}
                    )
                    response_text = chat_completion.choices[0].message.content
                    if response_text:
                        return _parse_json_response(response_text)
                except Exception as e:
                    logger.error(f"Groq API call failed with {g_model}: {e}")
            logger.error("All Groq models failed. Trying Hugging Face / OpenAI fallback...")
        
        # Check HuggingFace Serverless Inference API (Free Qwen-2.5 models)
        hf_token = os.getenv("HF_TOKEN", "")
        if hf_token or (not settings.GROQ_API_KEY and not settings.OPENAI_API_KEY):
            import requests
            headers = {"Content-Type": "application/json"}
            if hf_token:
                headers["Authorization"] = f"Bearer {hf_token}"
                
            # List of models to try (smaller models load fast and are highly cached on HF!)
            hf_models = [
                "Qwen/Qwen2.5-7B-Instruct",
                "Qwen/Qwen2.5-1.5B-Instruct",
                "Qwen/Qwen2.5-14B-Instruct",
                "Qwen/Qwen2.5-72B-Instruct"
            ]
            
            prompt_content = f"<|im_start|>system\n{SYSTEM_INSTRUCTION}<|im_end|>\n<|im_start|>user\nPersona: {persona['prompt']}\nMode: {mode}\nHistory:\n{history_str}\nStudent: {user_message}<|im_end|>\n<|im_start|>assistant\n"
            
            payload = {
                "inputs": prompt_content,
                "parameters": {
                    "max_new_tokens": 512,
                    "temperature": 0.7,
                    "return_full_text": False
                }
            }
            
            for model_id in hf_models:
                logger.info(f"Attempting Hugging Face Serverless Qwen API with model: {model_id}...")
                try:
                    api_url = f"https://api-inference.huggingface.co/models/{model_id}"
                    r = requests.post(api_url, json=payload, headers=headers, timeout=10)
                    if r.status_code == 200:
                        res_data = r.json()
                        text = ""
                        if isinstance(res_data, list) and len(res_data) > 0:
                            text = res_data[0].get("generated_text", "")
                        elif isinstance(res_data, dict) and "generated_text" in res_data:
                            text = res_data["generated_text"]
                            
                        if text:
                            logger.info(f"Successfully generated response using model: {model_id}")
                            return _parse_json_response(text)
                    else:
                        logger.warning(f"Model {model_id} returned status code {r.status_code}: {r.text[:100]}")
                        # Keep trying next models in the loop
                        continue
                except Exception as model_err:
                    logger.warning(f"Error querying model {model_id}: {model_err}")
                    continue

        # Try OpenAI next (Paid fallback)
        if settings.OPENAI_API_KEY:
            logger.info("Generating response via OpenAI GPT-4o-mini API...")
            try:
                from openai import OpenAI
                client = OpenAI(api_key=settings.OPENAI_API_KEY)
                chat_completion = client.chat.completions.create(
                    messages=[
                        {"role": "system", "content": SYSTEM_INSTRUCTION},
                        {"role": "user", "content": f"Persona: {persona['prompt']}\nMode: {mode}\nHistory:\n{history_str}\nStudent: {user_message}"}
                    ],
                    model="gpt-4o-mini",
                    temperature=0.7,
                    response_format={"type": "json_object"}
                )
                response_text = chat_completion.choices[0].message.content
                return _parse_json_response(response_text)
            except Exception as e:
                logger.error(f"OpenAI API call failed: {e}")
                
    # 2. Local Mode (or fallback to local if cloud fails)
    logger.info("Generating response locally...")
    try:
        # Check if Ollama is running (simplifies local execution and is faster than HF transformers)
        import requests
        try:
            # Let's check Ollama endpoint
            ollama_url = "http://localhost:11434/api/chat"
            payload = {
                "model": "qwen2.5:latest" if settings.LOCAL_LLM_MODEL.startswith("Qwen") else "llama3:latest",
                "messages": [
                    {"role": "system", "content": SYSTEM_INSTRUCTION},
                    {"role": "user", "content": f"Persona: {persona['prompt']}\nMode: {mode}\nHistory:\n{history_str}\nStudent: {user_message}"}
                ],
                "stream": False,
                "format": "json"
            }
            logger.info("Attempting to call local Ollama endpoint...")
            r = requests.post(ollama_url, json=payload, timeout=5)
            if r.status_code == 200:
                result = r.json()
                response_text = result["message"]["content"]
                logger.info("Local Ollama execution successful.")
                return _parse_json_response(response_text)
        except Exception as ollama_err:
            logger.debug(f"Ollama is not running or failed: {ollama_err}. Using local HF transformers...")

        # If Ollama is not running, run via HF transformers
        pipeline = get_local_llm_pipeline()
        
        # Qwen-2.5-Instruct format
        messages = [
            {"role": "system", "content": SYSTEM_INSTRUCTION},
            {"role": "user", "content": f"Persona: {persona['prompt']}\nMode: {mode}\nHistory:\n{history_str}\nStudent: {user_message}"}
        ]
        text = pipeline.tokenizer.apply_chat_template(
            messages,
            tokenize=False,
            add_generation_prompt=True
        )
        
        outputs = pipeline(text, return_full_text=False)
        response_text = outputs[0]["generated_text"].strip()
        logger.info(f"Local HF LLM result text: {response_text}")
        return _parse_json_response(response_text)
        
    except Exception as e:
        logger.error(f"Local LLM generation failed: {e}")
        # Return fallback mock JSON if everything fails so the app continues
        return _get_fallback_mock_response(user_message)

def _parse_json_response(text: str) -> Dict[str, Any]:
    text = text.strip()
    # Strip markdown block formatting if present
    if text.startswith("```json"):
        text = text[7:]
    elif text.startswith("```"):
        text = text[3:]
    if text.endswith("```"):
        text = text[:-3]
    text = text.strip()
    
    try:
        return json.loads(text)
    except Exception as e:
        logger.error(f"Failed to parse LLM response as JSON: {e}. Raw content: {text}")
        # Attempt to repair or use regex to extract, otherwise use fallback
        return {
            "reply": "I'm sorry, I encountered a slight error in analyzing that. Could you repeat it?",
            "corrections": [],
            "suggestions": [],
            "pronunciation_targets": ["conversation"],
            "cefr_estimate": "B1",
            "topics": ["General English"]
        }

def _get_fallback_mock_response(user_message: str) -> Dict[str, Any]:
    msg = user_message.lower().strip()
    
    # Dynamic rule-based mock answers for offline fallback
    if "hello" in msg or "hi " in msg or msg == "hi":
        reply = "Hello there! It is great to chat with you today. What would you like to talk about?"
        topics = ["Greetings"]
        pronunciation = ["discuss", "hello"]
    elif "how are you" in msg:
        reply = "I am doing very well, thank you for asking! How is your day going so far?"
        topics = ["Daily Conversation"]
        pronunciation = ["asking", "going"]
    elif "doing" in msg or "what are you" in msg:
        reply = "I am ready to help you practice English! We can discuss hobbies, travel, or work. What interests you?"
        topics = ["Hobbies & Interests"]
        pronunciation = ["practice", "interests"]
    elif "thank" in msg:
        reply = "You are very welcome! Don't hesitate to ask if you have any questions."
        topics = ["Politeness"]
        pronunciation = ["welcome", "questions"]
    else:
        reply = "That is really interesting! Could you explain more about what you mean by that?"
        topics = ["Elaborating thoughts"]
        pronunciation = ["explain", "interesting"]
        
    return {
        "reply": reply,
        "corrections": [],
        "suggestions": [
            "You could say: Let me explain my thoughts.",
            "Or: I would like to move to a new topic."
        ],
        "pronunciation_targets": pronunciation,
        "cefr_estimate": "B1",
        "topics": topics
    }
