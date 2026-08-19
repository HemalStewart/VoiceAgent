'use client';

import React, { useRef, useEffect } from 'react';
import { useVoiceStore } from '@/store/voiceStore';
import { User, Volume2, Sparkles, CheckCircle2, ChevronRight } from 'lucide-react';

export default function TranscriptPanel() {
  const { messages } = useVoiceStore();
  const bottomRef = useRef<HTMLDivElement | null>(null);

  // Auto-scroll to bottom
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  return (
    <div className="glass-panel rounded-2xl p-6 flex flex-col h-full">
      <div className="flex justify-between items-center pb-4 border-b border-gray-800/80 mb-4">
        <h2 className="text-lg font-bold text-gray-200 flex items-center gap-2">
          <Sparkles className="w-5 h-5 text-primary" />
          Live Transcript
        </h2>
        <span className="text-xs text-gray-500 font-semibold uppercase tracking-wider">
          {messages.length} messages
        </span>
      </div>

      {/* Message list container */}
      <div className="flex-1 overflow-y-auto pr-2 space-y-6">
        {messages.length === 0 ? (
          <div className="h-full flex flex-col items-center justify-center text-center p-8">
            <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center text-primary mb-3">
              <Volume2 className="w-6 h-6 animate-pulse" />
            </div>
            <p className="text-sm font-semibold text-gray-400">No conversation history yet.</p>
            <p className="text-xs text-gray-500 mt-1">Click "Start Speaking" to talk with the teacher.</p>
          </div>
        ) : (
          messages.map((msg, idx) => {
            const isUser = msg.role === 'user';
            return (
              <div
                key={idx}
                className={`flex gap-4 ${isUser ? 'flex-row-reverse' : 'flex-row'}`}
              >
                {/* Avatar Icon - Solid colors */}
                <div className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 shadow-md ${
                  isUser 
                    ? 'bg-[#db2777] text-white' 
                    : 'bg-[#4f46e5] text-white'
                }`}>
                  {isUser ? <User className="w-5 h-5" /> : <Sparkles className="w-5 h-5" />}
                </div>

                {/* Message Bubble content */}
                <div className={`flex flex-col max-w-[75%] gap-1.5 ${isUser ? 'items-end' : 'items-start'}`}>
                  {/* Speaker Label */}
                  <span className="text-xs text-gray-500 font-bold px-1">
                    {isUser ? 'You (Student)' : 'AI Teacher'}
                  </span>

                  {/* Speech Bubble - Solid flat colors */}
                  <div className={`rounded-2xl px-5 py-3.5 text-sm font-medium shadow-md ${
                    isUser
                      ? 'bg-[#22101b] text-pink-100 border border-[#db2777]/30 rounded-tr-none'
                      : 'bg-[#121421] text-indigo-100 border border-[#4f46e5]/30 rounded-tl-none'
                  }`}>
                    {msg.content}
                    
                    {/* Inline Pronunciation Targets (Assistant) */}
                    {!isUser && msg.pronunciation_targets && msg.pronunciation_targets.length > 0 && (
                      <div className="mt-3 pt-2.5 border-t border-gray-800 flex flex-wrap items-center gap-1.5 text-xs text-gray-400">
                        <span className="font-semibold text-indigo-400">Practice saying:</span>
                        {msg.pronunciation_targets.map((word, wIdx) => (
                          <span
                            key={wIdx}
                            className="bg-primary/20 text-indigo-300 font-bold px-2 py-0.5 rounded border border-primary/20 hover:bg-primary/30 cursor-pointer"
                          >
                            {word}
                          </span>
                        ))}
                      </div>
                    )}
                  </div>

                  {/* Inline Grammar Correction alert (User) */}
                  {isUser && msg.grammar_corrections && msg.grammar_corrections.length > 0 && (
                    <div className="w-full mt-1.5 bg-amber-500/10 border border-amber-500/20 rounded-xl p-3 flex flex-col gap-2">
                      <span className="text-[11px] font-bold text-amber-400 flex items-center gap-1 uppercase tracking-wider">
                        <CheckCircle2 className="w-3.5 h-3.5" />
                        Grammar Check
                      </span>
                      {msg.grammar_corrections.map((corr, cIdx) => (
                        <div key={cIdx} className="text-xs text-gray-300 leading-relaxed">
                          <div className="flex flex-wrap items-center gap-1">
                            <span className="line-through text-red-400 font-semibold">{corr.original}</span>
                            <ChevronRight className="w-3 h-3 text-amber-500" />
                            <span className="text-green-400 font-bold">{corr.corrected}</span>
                          </div>
                          <p className="text-gray-400 mt-0.5 text-[11px] italic">{corr.explanation}</p>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            );
          })
        )}
        <div ref={bottomRef} />
      </div>
    </div>
  );
}
