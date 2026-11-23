'use client';

import React from 'react';
import TutorWorkspace from '@/components/voice/TutorWorkspace';
import TranscriptPanel from '@/components/voice/TranscriptPanel';
import FeedbackPanel from '@/components/voice/FeedbackPanel';
import { Sparkles, MessageCircle, Mic, Star } from 'lucide-react';

export default function Home() {
  return (
    <div className="h-screen w-screen flex flex-col p-4 md:p-6 gap-6 bg-[#000000] text-gray-100 overflow-hidden">
      {/* Header section (Flat dark border, no gradients) */}
      <header className="flex flex-col sm:flex-row items-center justify-between border-b border-[#27272a] pb-4 shrink-0 gap-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-[#27272a] flex items-center justify-center shadow-md">
            <Mic className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-xl font-black tracking-tight text-white flex items-center gap-2">
              EnglishMind <span className="text-[10px] bg-[#27272a] text-indigo-400 border border-[#3f3f46] font-bold px-2 py-0.5 rounded-full">v1.0 AI Tutor</span>
            </h1>
            <p className="text-[11px] text-gray-400 font-medium">Your personal high-accuracy spoken English learning companion</p>
          </div>
        </div>

        {/* Feature Highlights (Flat backgrounds, no gradients) */}
        <div className="flex items-center gap-3 text-[10px] text-gray-400">
          <div className="flex items-center gap-1.5 bg-[#121212] px-2.5 py-1 rounded-xl border border-[#27272a]">
            <Sparkles className="w-3.5 h-3.5 text-indigo-500" />
            <span>Whisper Speech ASR</span>
          </div>
          <div className="flex items-center gap-1.5 bg-[#121212] px-2.5 py-1 rounded-xl border border-[#27272a]">
            <Star className="w-3.5 h-3.5 text-pink-500" />
            <span>Kokoro-82M TTS Voice</span>
          </div>
          <div className="flex items-center gap-1.5 bg-[#121212] px-2.5 py-1 rounded-xl border border-[#27272a]">
            <MessageCircle className="w-3.5 h-3.5 text-emerald-500" />
            <span>CEFR & Grammar Feedback</span>
          </div>
        </div>
      </header>

      {/* Main dashboard grid - fills 100% remaining screen height */}
      <main className="flex-1 min-h-0 grid grid-cols-12 gap-6 items-stretch">
        {/* Left Side: Tutor Workspace (Takes col-span-5 height-full) */}
        <section className="col-span-12 lg:col-span-5 flex flex-col gap-4 h-full min-h-0">
          <div className="flex-1 min-h-0">
            <TutorWorkspace />
          </div>
          
          {/* Quick tips panel (Flat styles) */}
          <div className="glass-panel rounded-2xl p-4 border-l-4 border-l-[#27272a] flex gap-3 shrink-0">
            <div className="w-8 h-8 rounded-full bg-[#27272a] flex items-center justify-center shrink-0 text-indigo-400">
              <Sparkles className="w-4 h-4" />
            </div>
            <div>
              <h4 className="text-[11px] font-bold text-gray-300 uppercase tracking-wider">Practice Tip</h4>
              <p className="text-[11px] text-gray-400 mt-0.5 leading-relaxed">
                Click "Start Speaking" and converse with your tutor. Try talking for at least 10-15 seconds to receive detailed feedback on your sentence structure!
              </p>
            </div>
          </div>
        </section>

        {/* Right Side: Transcript & Feedback panels (col-span-7 h-full) */}
        <section className="col-span-12 lg:col-span-7 grid grid-cols-1 md:grid-cols-2 gap-6 h-full min-h-0">
          <div className="h-full min-h-0">
            <TranscriptPanel />
          </div>
          <div className="h-full min-h-0">
            <FeedbackPanel />
          </div>
        </section>
      </main>

      {/* Footer (Shrink to fit) */}
      <footer className="border-t border-[#27272a] pt-3 text-center text-[10px] text-gray-500 shrink-0">
        <p>© 2026 EnglishMind AI Agent Platform. 100% Private, Self-Hosted Speech Pipeline.</p>
      </footer>
    </div>
  );
}
