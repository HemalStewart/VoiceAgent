import sqlite3
import json
import os
from datetime import datetime
from typing import List, Dict, Any, Optional

DB_FILE = "voice_agent.db"

def get_db_connection():
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Create sessions table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS sessions (
        session_id TEXT PRIMARY KEY,
        persona TEXT NOT NULL,
        mode TEXT NOT NULL,
        created_at TEXT NOT NULL
    )
    """)
    
    # Create messages table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS messages (
        message_id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        audio_path TEXT,
        grammar_corrections TEXT, -- JSON string
        suggestions TEXT,         -- JSON string
        pronunciation_targets TEXT, -- JSON string
        cefr_estimate TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions(session_id)
    )
    """)
    
    conn.commit()
    conn.close()

def create_session(session_id: str, persona: str, mode: str) -> Dict[str, Any]:
    conn = get_db_connection()
    cursor = conn.cursor()
    created_at = datetime.utcnow().isoformat()
    
    cursor.execute(
        "INSERT INTO sessions (session_id, persona, mode, created_at) VALUES (?, ?, ?, ?)",
        (session_id, persona, mode, created_at)
    )
    
    conn.commit()
    conn.close()
    
    return {
        "session_id": session_id,
        "persona": persona,
        "mode": mode,
        "created_at": created_at
    }

def get_session(session_id: str) -> Optional[Dict[str, Any]]:
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM sessions WHERE session_id = ?", (session_id,))
    row = cursor.fetchone()
    conn.close()
    
    if row:
        return dict(row)
    return None

def add_message(
    message_id: str,
    session_id: str,
    role: str,
    content: str,
    audio_path: Optional[str] = None,
    grammar_corrections: Optional[List[Dict[str, Any]]] = None,
    suggestions: Optional[List[str]] = None,
    pronunciation_targets: Optional[List[str]] = None,
    cefr_estimate: Optional[str] = None
) -> Dict[str, Any]:
    conn = get_db_connection()
    cursor = conn.cursor()
    created_at = datetime.utcnow().isoformat()
    
    corrections_str = json.dumps(grammar_corrections) if grammar_corrections else None
    suggestions_str = json.dumps(suggestions) if suggestions else None
    targets_str = json.dumps(pronunciation_targets) if pronunciation_targets else None
    
    cursor.execute("""
        INSERT INTO messages (
            message_id, session_id, role, content, audio_path, 
            grammar_corrections, suggestions, pronunciation_targets, cefr_estimate, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        message_id, session_id, role, content, audio_path,
        corrections_str, suggestions_str, targets_str, cefr_estimate, created_at
    ))
    
    conn.commit()
    conn.close()
    
    return {
        "message_id": message_id,
        "session_id": session_id,
        "role": role,
        "content": content,
        "audio_path": audio_path,
        "grammar_corrections": grammar_corrections or [],
        "suggestions": suggestions or [],
        "pronunciation_targets": pronunciation_targets or [],
        "cefr_estimate": cefr_estimate,
        "created_at": created_at
    }

def get_session_history(session_id: str) -> List[Dict[str, Any]]:
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT * FROM messages WHERE session_id = ? ORDER BY created_at ASC",
        (session_id,)
    )
    rows = cursor.fetchall()
    conn.close()
    
    history = []
    for row in rows:
        item = dict(row)
        item["grammar_corrections"] = json.loads(item["grammar_corrections"]) if item["grammar_corrections"] else []
        item["suggestions"] = json.loads(item["suggestions"]) if item["suggestions"] else []
        item["pronunciation_targets"] = json.loads(item["pronunciation_targets"]) if item["pronunciation_targets"] else []
        history.append(item)
    return history

def get_analytics() -> Dict[str, Any]:
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Total sessions
    cursor.execute("SELECT COUNT(*) as count FROM sessions")
    total_sessions = cursor.fetchone()["count"]
    
    # Total messages
    cursor.execute("SELECT COUNT(*) as count FROM messages WHERE role = 'user'")
    total_user_messages = cursor.fetchone()["count"]
    
    # Get all grammar corrections
    cursor.execute("SELECT grammar_corrections FROM messages WHERE role = 'user' AND grammar_corrections IS NOT NULL")
    rows = cursor.fetchall()
    
    all_corrections = []
    for row in rows:
        corrections = json.loads(row["grammar_corrections"])
        if corrections:
            all_corrections.extend(corrections)
            
    # Estimate CEFR distribution
    cursor.execute("SELECT cefr_estimate, COUNT(*) as count FROM messages WHERE role = 'user' AND cefr_estimate IS NOT NULL GROUP BY cefr_estimate")
    cefr_rows = cursor.fetchall()
    cefr_distribution = {row["cefr_estimate"]: row["count"] for row in cefr_rows}
    
    conn.close()
    
    return {
        "total_sessions": total_sessions,
        "total_user_messages": total_user_messages,
        "recent_mistakes": all_corrections[-10:] if all_corrections else [],
        "cefr_distribution": cefr_distribution
    }

# Initialize on import
init_db()
