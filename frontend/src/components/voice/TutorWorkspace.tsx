'use client';

import React, { useState, useRef, useEffect } from 'react';
import { useVoiceStore } from '@/store/voiceStore';
import { Mic, Square, Sparkles, Volume2, HelpCircle } from 'lucide-react';

export default function TutorWorkspace() {
  const {
    persona,
    setPersona,
    mode,
    setMode,
    isRecording,
    setRecording,
    isThinking,
    isPlaying,
    sendVoiceAudio,
    sendTextTranscript,
    currentTranscript,
    sessionId,
    startNewSession
  } = useVoiceStore();

  const [stream, setStream] = useState<MediaStream | null>(null);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioChunksRef = useRef<Blob[]>([]);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const animationFrameRef = useRef<number | null>(null);
  const audioContextRef = useRef<AudioContext | null>(null);
  const analyserRef = useRef<AnalyserNode | null>(null);
  
  // SpeechRecognition references
  const recognitionRef = useRef<any>(null);
  const transcriptAccumulatorRef = useRef<string>("");

  // Initialize session on mount if not exists
  useEffect(() => {
    if (!sessionId) {
      startNewSession().catch(err => console.error("Initial session start failed:", err));
    }
  }, [sessionId, startNewSession]);

  // Handler for canvas drawing (microphone volume visualization)
  const drawWaveform = () => {
    if (!canvasRef.current || !analyserRef.current) return;
    const canvas = canvasRef.current;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const analyser = analyserRef.current;
    const bufferLength = analyser.frequencyBinCount;
    const dataArray = new Uint8Array(bufferLength);

    const draw = () => {
      if (!isRecording) return;
      animationFrameRef.current = requestAnimationFrame(draw);
      
      analyser.getByteTimeDomainData(dataArray);
      
      ctx.fillStyle = '#0d0e12';
      ctx.fillRect(0, 0, canvas.width, canvas.height);
      
      ctx.lineWidth = 3;
      ctx.strokeStyle = '#4f46e5';
      
      ctx.beginPath();
      
      const sliceWidth = canvas.width / bufferLength;
      let x = 0;
      
      for (let i = 0; i < bufferLength; i++) {
        const v = dataArray[i] / 128.0;
        const y = (v * canvas.height) / 2;
        
        if (i === 0) {
          ctx.moveTo(x, y);
        } else {
          ctx.lineTo(x, y);
        }
        
        x += sliceWidth;
      }
      
      ctx.lineTo(canvas.width, canvas.height / 2);
      ctx.stroke();
    };

    draw();
  };

  // Start Voice Recording
  const startRecording = async () => {
    try {
      audioChunksRef.current = [];
      const audioStream = await navigator.mediaDevices.getUserMedia({ audio: true });
      setStream(audioStream);

      // Web Audio API setup for visualizer
      const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
      const analyser = audioContext.createAnalyser();
      analyser.fftSize = 256;
      
      const source = audioContext.createMediaStreamSource(audioStream);
      source.connect(analyser);
      
      audioContextRef.current = audioContext;
      analyserRef.current = analyser;

      // Check supported MIME type
      let mimeType = 'audio/webm';
      if (MediaRecorder.isTypeSupported('audio/ogg;codecs=opus')) {
        mimeType = 'audio/ogg;codecs=opus';
      } else if (MediaRecorder.isTypeSupported('audio/mp4')) {
        mimeType = 'audio/mp4';
      } else if (MediaRecorder.isTypeSupported('audio/wav')) {
        mimeType = 'audio/wav';
      }

      // 1. Initialize Browser SpeechRecognition if supported (Free Speech-to-Text)
      const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
      if (SpeechRecognition) {
        transcriptAccumulatorRef.current = "";
        const recognition = new SpeechRecognition();
        recognition.continuous = true;
        recognition.interimResults = true;
        
        // Select accent based on Persona
        recognition.lang = persona === 'emma' ? 'en-GB' : 'en-US';
        
        recognition.onresult = (event: any) => {
          let interimTranscript = "";
          let finalTranscript = "";
          
          for (let i = event.resultIndex; i < event.results.length; ++i) {
            if (event.results[i].isFinal) {
              finalTranscript += event.results[i][0].transcript;
            } else {
              interimTranscript += event.results[i][0].transcript;
            }
          }
          
          if (finalTranscript) {
            transcriptAccumulatorRef.current = (transcriptAccumulatorRef.current + " " + finalTranscript).trim();
          }
          
          useVoiceStore.setState({ 
            currentTranscript: (transcriptAccumulatorRef.current + " " + interimTranscript).trim() 
          });
        };
        
        recognition.onerror = (err: any) => {
          console.error("Speech Recognition Error:", err);
        };
        
        recognitionRef.current = recognition;
        recognition.start();
      }

      const recorder = new MediaRecorder(audioStream, { mimeType });
      
      recorder.ondataavailable = (event) => {
        if (event.data && event.data.size > 0) {
          audioChunksRef.current.push(event.data);
        }
      };

      recorder.onstop = async () => {
        // Stop browser SpeechRecognition
        if (recognitionRef.current) {
          try {
            recognitionRef.current.stop();
          } catch (e) {}
        }
        
        // Delay processing slightly to allow SpeechRecognition final results to accumulate
        setTimeout(async () => {
          const finalText = transcriptAccumulatorRef.current.trim();
          
          if (SpeechRecognition && finalText) {
            // Process via free text-based endpoint
            await sendTextTranscript(finalText);
          } else {
            // Web Speech not supported or returned empty text: fall back to raw audio upload
            const audioBlob = new Blob(audioChunksRef.current, { type: recorder.mimeType });
            await sendVoiceAudio(audioBlob);
          }
        }, 300);
      };

      mediaRecorderRef.current = recorder;
      recorder.start(100); // chunk every 100ms
      setRecording(true);
      
      // Delay visualizer draw slightly to ensure context is active
      setTimeout(() => {
        drawWaveform();
      }, 50);

    } catch (error) {
      console.error('Error opening microphone:', error);
      alert('Could not open microphone. Please allow microphone permissions.');
    }
  };

  // Stop Recording
  const stopRecording = () => {
    if (mediaRecorderRef.current && isRecording) {
      mediaRecorderRef.current.stop();
    }
    
    if (stream) {
      stream.getTracks().forEach((track) => track.stop());
      setStream(null);
    }
    
    if (audioContextRef.current) {
      audioContextRef.current.close();
      audioContextRef.current = null;
    }
    
    if (animationFrameRef.current) {
      cancelAnimationFrame(animationFrameRef.current);
    }

    setRecording(false);
  };

  // Handle persona change
  const handlePersonaChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setPersona(e.target.value as any);
    // Restart session for new tutor
    startNewSession();
  };

  // Handle lesson mode change
  const handleModeChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setMode(e.target.value as any);
    // Restart session for new lesson theme
    startNewSession();
  };

  return (
    <div className="glass-panel rounded-2xl p-6 flex flex-col items-center justify-between h-full relative overflow-hidden">

      {/* Control bar */}
      <div className="w-full flex flex-col sm:flex-row gap-4 justify-between items-center z-10">
        {/* Persona Select */}
        <div className="flex items-center gap-2">
          <span className="text-sm font-semibold text-gray-400">Teacher:</span>
          <select
            value={persona}
            onChange={handlePersonaChange}
            className="bg-[#1a1d29] border border-gray-800 text-gray-200 rounded-xl px-4 py-2 text-sm focus:outline-none focus:border-primary transition"
          >
            <option value="emma">Emma (British RP Accent)</option>
            <option value="alex">Alex (American Accent)</option>
            <option value="sophia">Sophia (Business English)</option>
          </select>
        </div>

        {/* Mode Select */}
        <div className="flex items-center gap-2">
          <span className="text-sm font-semibold text-gray-400">Mode:</span>
          <select
            value={mode}
            onChange={handleModeChange}
            className="bg-[#1a1d29] border border-gray-800 text-gray-200 rounded-xl px-4 py-2 text-sm focus:outline-none focus:border-primary transition"
          >
            <option value="free_chat">Free Conversation</option>
            <option value="guided">Guided Discussion</option>
            <option value="ielts">IELTS Prep Speaking</option>
            <option value="roleplay">Roleplay (Job Interview/Cafe)</option>
          </select>
        </div>
      </div>

      {/* Center Interactive Avatar */}
      <div className="my-8 flex flex-col items-center justify-center z-10">
        {/* State: Thinking (Modern Siri-like Breathing Orb) */}
        {isThinking && (
          <div className="relative w-36 h-36 flex items-center justify-center">
            {/* Blurry overlaid morphing orbs */}
            <div className="absolute w-28 h-28 siri-orb siri-orb-indigo opacity-70"></div>
            <div className="absolute w-28 h-28 siri-orb siri-orb-pink opacity-60"></div>
            <div className="absolute w-28 h-28 siri-orb siri-orb-emerald opacity-70"></div>
            
            {/* Core point */}
            <div className="absolute w-6 h-6 rounded-full bg-white shadow-lg shadow-white/80 animate-pulse"></div>
          </div>
        )}

        {/* State: Speaking (Jumping Audio Bars) */}
        {isPlaying && !isThinking && (
          <div className="h-36 flex items-end justify-center gap-2 px-10">
            <div className="w-3 h-16 bg-primary rounded-full bar-anim-1 origin-bottom"></div>
            <div className="w-3 h-24 bg-secondary rounded-full bar-anim-2 origin-bottom"></div>
            <div className="w-3 h-32 bg-accent rounded-full bar-anim-3 origin-bottom"></div>
            <div className="w-3 h-20 bg-primary rounded-full bar-anim-4 origin-bottom"></div>
            <div className="w-3 h-12 bg-secondary rounded-full bar-anim-5 origin-bottom"></div>
          </div>
        )}

        {/* State: Listening (Draw Canvas Waveform) */}
        {isRecording && (
          <div className="w-64 h-36 flex items-center justify-center rounded-2xl overflow-hidden bg-[#0d0e12] border border-gray-900">
            <canvas ref={canvasRef} width={256} height={144} className="w-full h-full" />
          </div>
        )}

        {/* State: Idle */}
        {!isRecording && !isThinking && !isPlaying && (
          <div className="w-36 h-36 rounded-full bg-[#1b2035] border-2 border-primary/30 flex items-center justify-center shadow-lg relative group">
            <div className="absolute inset-0 rounded-full bg-primary/10 animate-ping opacity-60 pointer-events-none"></div>
            <Volume2 className="w-12 h-12 text-primary/75 group-hover:scale-110 transition duration-300" />
          </div>
        )}

        {/* Status Badge */}
        <span className="mt-6 text-sm font-semibold tracking-wider text-gray-400 uppercase">
          {isThinking ? 'Tutor is thinking...' : isPlaying ? 'Tutor is speaking' : isRecording ? 'Listening...' : 'Ready to talk'}
        </span>
      </div>

      {/* Bottom control / output */}
      <div className="w-full flex flex-col items-center gap-4 z-10">
        {currentTranscript && (
          <p className="text-center text-sm italic text-gray-300 max-w-lg line-clamp-2 px-4">
            "{currentTranscript}"
          </p>
        )}

        {/* Mic Control Button - Solid flat color */}
        {!isRecording ? (
          <button
            onClick={startRecording}
            disabled={isThinking || isPlaying}
            className="flex items-center gap-3 bg-[#4f46e5] hover:bg-[#4338ca] text-white font-bold py-4 px-8 rounded-full shadow-md active:scale-95 disabled:opacity-50 disabled:scale-100 transition duration-300"
          >
            <Mic className="w-5 h-5" />
            Start Speaking
          </button>
        ) : (
          <button
            onClick={stopRecording}
            className="flex items-center gap-3 bg-[#db2777] hover:bg-[#be185d] text-white font-bold py-4 px-8 rounded-full shadow-md active:scale-95 transition duration-300 mic-active"
          >
            <Square className="w-5 h-5" />
            Stop & Submit
          </button>
        )}
      </div>
    </div>
  );
}
