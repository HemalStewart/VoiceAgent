import { create } from 'zustand';

export interface Correction {
  original: string;
  corrected: string;
  explanation: string;
}

export interface Message {
  message_id?: string;
  role: 'user' | 'assistant';
  content: string;
  audio_path?: string | null;
  grammar_corrections?: Correction[];
  suggestions?: string[];
  pronunciation_targets?: string[];
  cefr_estimate?: string;
  created_at?: string;
}

export interface Analytics {
  total_sessions: number;
  total_user_messages: number;
  recent_mistakes: Correction[];
  cefr_distribution: Record<string, number>;
}

interface VoiceState {
  // Session details
  sessionId: string | null;
  persona: 'emma' | 'alex' | 'sophia';
  mode: 'free_chat' | 'guided' | 'ielts' | 'roleplay';
  
  // App UI states
  isRecording: boolean;
  isThinking: boolean;
  isPlaying: boolean;
  
  // Chat content
  messages: Message[];
  currentTranscript: string;
  
  // Analytics
  analytics: Analytics | null;
  
  // Actions
  setPersona: (persona: 'emma' | 'alex' | 'sophia') => void;
  setMode: (mode: 'free_chat' | 'guided' | 'ielts' | 'roleplay') => void;
  setRecording: (isRecording: boolean) => void;
  setThinking: (isThinking: boolean) => void;
  setPlaying: (isPlaying: boolean) => void;
  setCurrentTranscript: (transcript: string) => void;
  
  // Session initialization
  startNewSession: () => Promise<string>;
  loadSessionHistory: (sessionId: string) => Promise<void>;
  
  // Processing voice
  sendVoiceAudio: (audioBlob: Blob) => Promise<void>;
  sendTextTranscript: (text: string) => Promise<void>;
  
  // Analytics fetch
  fetchAnalytics: () => Promise<void>;
  resetSession: () => void;
}

const BACKEND_URL = 'http://localhost:8000';

export const useVoiceStore = create<VoiceState>((set, get) => ({
  sessionId: null,
  persona: 'emma',
  mode: 'free_chat',
  isRecording: false,
  isThinking: false,
  isPlaying: false,
  messages: [],
  currentTranscript: '',
  analytics: null,

  setPersona: (persona) => set({ persona }),
  setMode: (mode) => set({ mode }),
  setRecording: (isRecording) => set({ isRecording }),
  setThinking: (isThinking) => set({ isThinking }),
  setPlaying: (isPlaying) => set({ isPlaying }),
  setCurrentTranscript: (currentTranscript) => set({ currentTranscript }),

  startNewSession: async () => {
    const { persona, mode } = get();
    try {
      const formData = new FormData();
      formData.append('persona', persona);
      formData.append('mode', mode);

      const response = await fetch(`${BACKEND_URL}/api/sessions`, {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) throw new Error('Failed to start session');
      const data = await response.json();
      set({ sessionId: data.session_id, messages: [] });
      return data.session_id;
    } catch (error) {
      console.error('Error starting session:', error);
      throw error;
    }
  },

  loadSessionHistory: async (sessionId: string) => {
    try {
      const response = await fetch(`${BACKEND_URL}/api/sessions/${sessionId}/history`);
      if (!response.ok) throw new Error('Failed to fetch history');
      const data = await response.json();
      
      const formattedHistory = data.history.map((msg: any) => ({
        ...msg,
        audio_path: msg.audio_path ? `${BACKEND_URL}${msg.audio_path}` : null
      }));
      
      set({ sessionId: data.session.session_id, messages: formattedHistory });
    } catch (error) {
      console.error('Error loading history:', error);
    }
  },

  sendVoiceAudio: async (audioBlob: Blob) => {
    let { sessionId, startNewSession, persona } = get();
    
    // Ensure active session exists
    if (!sessionId) {
      sessionId = await startNewSession();
    }

    set({ isThinking: true, currentTranscript: 'Processing voice...' });

    try {
      const formData = new FormData();
      formData.append('session_id', sessionId!);
      formData.append('audio', audioBlob, 'audio.wav');

      const response = await fetch(`${BACKEND_URL}/api/process-audio`, {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || 'Failed to process audio');
      }
      
      const data = await response.json();
      
      // Update transcript display
      set({ currentTranscript: data.user_transcript });

      // Add user and assistant messages to state
      const userMsg: Message = {
        role: 'user',
        content: data.user_transcript,
        grammar_corrections: data.corrections,
        suggestions: data.suggestions,
        cefr_estimate: data.cefr_estimate,
        audio_path: data.user_audio_url ? `${BACKEND_URL}${data.user_audio_url}` : null
      };

      const tutorMsg: Message = {
        role: 'assistant',
        content: data.tutor_reply,
        pronunciation_targets: data.pronunciation_targets,
        audio_path: data.tutor_audio_url ? `${BACKEND_URL}${data.tutor_audio_url}` : null
      };

      set((state) => ({
        messages: [...state.messages, userMsg, tutorMsg],
        isThinking: false
      }));

      // Play synthesized audio (if base64 is available) or fallback to Browser-native free TTS
      let audioPlayed = false;
      if (data.tutor_audio_base64) {
        try {
          const audioSrc = `data:audio/wav;base64,${data.tutor_audio_base64}`;
          const audio = new Audio(audioSrc);
          
          audio.onplay = () => set({ isPlaying: true });
          audio.onended = () => set({ isPlaying: false });
          audio.onerror = () => set({ isPlaying: false });
          
          await audio.play();
          audioPlayed = true;
        } catch (playErr) {
          console.error("Base64 audio playback failed, trying browser TTS:", playErr);
        }
      }
      
      // Fallback: Free browser-native SpeechSynthesis
      if (!audioPlayed && typeof window !== 'undefined' && 'speechSynthesis' in window) {
        window.speechSynthesis.cancel(); // Stop any active reading
        const utterance = new SpeechSynthesisUtterance(data.tutor_reply);
        
        // Load voices and select based on persona gender & accent
        const voices = window.speechSynthesis.getVoices();
        const lowerPersona = persona.toLowerCase();
        let voice = null;
        
        if (lowerPersona === 'emma') {
          // Look for British English Female voice
          const gbVoices = voices.filter(v => v.lang.startsWith('en-GB') || v.lang.includes('en_GB'));
          voice = gbVoices.find(v => {
            const name = v.name.toLowerCase();
            return name.includes('female') || name.includes('kate') || name.includes('serena') || name.includes('stephanie') || name.includes('samantha') || name.includes('hazel') || name.includes('fiona');
          }) || gbVoices.find(v => v.name.toLowerCase().includes('daniel') === false) || gbVoices[0] || voices.find(v => v.lang.startsWith('en-US')) || voices[0];
          
        } else if (lowerPersona === 'alex') {
          // Look for American English Male voice
          const usVoices = voices.filter(v => v.lang.startsWith('en-US') || v.lang.includes('en_US'));
          voice = usVoices.find(v => {
            const name = v.name.toLowerCase();
            return name.includes('male') || name.includes('alex') || name.includes('fred') || name.includes('tom') || name.includes('daniel') || name.includes('samantha') === false;
          }) || usVoices[0] || voices[0];
          
        } else {
          // Sophia (American Female)
          const usVoices = voices.filter(v => v.lang.startsWith('en-US') || v.lang.includes('en_US'));
          voice = usVoices.find(v => {
            const name = v.name.toLowerCase();
            return name.includes('female') || name.includes('samantha') || name.includes('siri') || name.includes('tessa') || name.includes('karen') || name.includes('sara') || name.includes('victoria');
          }) || usVoices[0] || voices[0];
        }
        
        if (voice) {
          utterance.voice = voice;
        }
        
        utterance.rate = 0.95; // Slightly slower, easier for language learners
        
        utterance.onstart = () => set({ isPlaying: true });
        utterance.onend = () => set({ isPlaying: false });
        utterance.onerror = () => set({ isPlaying: false });
        
        window.speechSynthesis.speak(utterance);
      }
      
      // Fetch fresh analytics
      get().fetchAnalytics();

    } catch (error) {
      console.error('Error processing audio:', error);
      set({ isThinking: false, currentTranscript: 'Error processing audio. Please try again.' });
    }
  },

  sendTextTranscript: async (text: string) => {
    let { sessionId, startNewSession, persona } = get();
    
    if (!sessionId) {
      sessionId = await startNewSession();
    }

    set({ isThinking: true, currentTranscript: text });

    try {
      const formData = new FormData();
      formData.append('session_id', sessionId!);
      formData.append('text', text);

      const response = await fetch(`${BACKEND_URL}/api/process-text`, {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || 'Failed to process text');
      }
      
      const data = await response.json();

      const userMsg: Message = {
        role: 'user',
        content: text,
        grammar_corrections: data.corrections,
        suggestions: data.suggestions,
        cefr_estimate: data.cefr_estimate,
        audio_path: null
      };

      const tutorMsg: Message = {
        role: 'assistant',
        content: data.tutor_reply,
        pronunciation_targets: data.pronunciation_targets,
        audio_path: null
      };

      set((state) => ({
        messages: [...state.messages, userMsg, tutorMsg],
        isThinking: false
      }));

      // Play synthesized audio (using browser TTS)
      if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
        window.speechSynthesis.cancel();
        const utterance = new SpeechSynthesisUtterance(data.tutor_reply);
        
        // Load voices and select based on persona gender & accent
        const voices = window.speechSynthesis.getVoices();
        const lowerPersona = persona.toLowerCase();
        let voice = null;
        
        if (lowerPersona === 'emma') {
          // Look for British English Female voice
          const gbVoices = voices.filter(v => v.lang.startsWith('en-GB') || v.lang.includes('en_GB'));
          voice = gbVoices.find(v => {
            const name = v.name.toLowerCase();
            return name.includes('female') || name.includes('kate') || name.includes('serena') || name.includes('stephanie') || name.includes('samantha') || name.includes('hazel') || name.includes('fiona');
          }) || gbVoices.find(v => v.name.toLowerCase().includes('daniel') === false) || gbVoices[0] || voices.find(v => v.lang.startsWith('en-US')) || voices[0];
          
        } else if (lowerPersona === 'alex') {
          // Look for American English Male voice
          const usVoices = voices.filter(v => v.lang.startsWith('en-US') || v.lang.includes('en_US'));
          voice = usVoices.find(v => {
            const name = v.name.toLowerCase();
            return name.includes('male') || name.includes('alex') || name.includes('fred') || name.includes('tom') || name.includes('daniel') || name.includes('samantha') === false;
          }) || usVoices[0] || voices[0];
          
        } else {
          // Sophia (American Female)
          const usVoices = voices.filter(v => v.lang.startsWith('en-US') || v.lang.includes('en_US'));
          voice = usVoices.find(v => {
            const name = v.name.toLowerCase();
            return name.includes('female') || name.includes('samantha') || name.includes('siri') || name.includes('tessa') || name.includes('karen') || name.includes('sara') || name.includes('victoria');
          }) || usVoices[0] || voices[0];
        }
        
        if (voice) {
          utterance.voice = voice;
        }
        utterance.rate = 0.95;
        
        utterance.onstart = () => set({ isPlaying: true });
        utterance.onend = () => set({ isPlaying: false });
        utterance.onerror = () => set({ isPlaying: false });
        
        window.speechSynthesis.speak(utterance);
      }
      
      get().fetchAnalytics();

    } catch (error) {
      console.error('Error processing text:', error);
      set({ isThinking: false, currentTranscript: 'Error processing text. Please try again.' });
    }
  },

  fetchAnalytics: async () => {
    try {
      const response = await fetch(`${BACKEND_URL}/api/analytics`);
      if (!response.ok) throw new Error('Failed to fetch analytics');
      const data = await response.json();
      set({ analytics: data });
    } catch (error) {
      console.error('Error fetching analytics:', error);
    }
  },

  resetSession: () => {
    set({ sessionId: null, messages: [], currentTranscript: '' });
  }
}));
