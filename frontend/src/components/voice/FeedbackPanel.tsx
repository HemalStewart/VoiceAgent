'use client';

import React, { useEffect } from 'react';
import { useVoiceStore } from '@/store/voiceStore';
import { Award, AlertTriangle, Lightbulb, BookOpen, BarChart3, RotateCcw } from 'lucide-react';

export default function FeedbackPanel() {
  const { analytics, fetchAnalytics, sessionId, resetSession, messages } = useVoiceStore();

  useEffect(() => {
    fetchAnalytics();
  }, [sessionId, fetchAnalytics]);

  // Extract latest CEFR level from history if available
  const latestCEFR = messages
    .filter((m) => m.role === 'user' && m.cefr_estimate)
    .map((m) => m.cefr_estimate)
    .pop() || 'A1';

  // Extract all grammar corrections from the current active conversation
  const currentCorrections = messages
    .filter((m) => m.role === 'user' && m.grammar_corrections && m.grammar_corrections.length > 0)
    .flatMap((m) => m.grammar_corrections || []);

  // Extract alternative suggestions from the current active conversation
  const currentSuggestions = messages
    .filter((m) => m.role === 'user' && msgHasSuggestions(m))
    .flatMap((m) => m.suggestions || []);

  function msgHasSuggestions(m: any) {
    return m.suggestions && m.suggestions.length > 0;
  }

  return (
    <div className="glass-panel rounded-2xl p-6 flex flex-col h-full">
      <div className="flex justify-between items-center pb-4 border-b border-gray-800/80 mb-6">
        <h2 className="text-lg font-bold text-gray-200 flex items-center gap-2">
          <BarChart3 className="w-5 h-5 text-secondary" />
          Feedback & Analytics
        </h2>
        {sessionId && (
          <button
            onClick={resetSession}
            className="text-xs text-gray-400 hover:text-white flex items-center gap-1 bg-[#1a1d29] px-2.5 py-1.5 rounded-lg border border-gray-800 transition"
          >
            <RotateCcw className="w-3.5 h-3.5" />
            Reset Session
          </button>
        )}
      </div>

      <div className="flex-1 overflow-y-auto space-y-6 pr-2">
        {/* CEFR Rank Card - Solid layout (No gradients) */}
        <div className="bg-[#131625] border border-[#4f46e5]/30 rounded-2xl p-5 flex items-center justify-between">
          <div className="flex flex-col gap-1">
            <span className="text-xs font-bold text-indigo-400 uppercase tracking-wider">Estimated Level</span>
            <span className="text-lg font-extrabold text-white">CEFR Fluency Ranking</span>
            <p className="text-xs text-gray-400 mt-1">Calculated in real-time based on your sentence structures and vocabulary complexity.</p>
          </div>
          <div className="w-16 h-16 rounded-2xl badge-cefr flex items-center justify-center text-2xl font-black text-white shadow-lg shrink-0">
            {latestCEFR}
          </div>
        </div>

        {/* Current Session Corrections */}
        <div>
          <h3 className="text-sm font-bold text-gray-300 flex items-center gap-2 mb-3">
            <AlertTriangle className="w-4 h-4 text-amber-500" />
            Grammar Improvements ({currentCorrections.length})
          </h3>
          {currentCorrections.length === 0 ? (
            <div className="bg-[#131622] rounded-2xl p-4 text-center border border-gray-900">
              <p className="text-xs text-gray-400">No grammar mistakes detected so far!</p>
              <p className="text-[10px] text-gray-500 mt-0.5">Keep speaking naturally to evaluate your skills.</p>
            </div>
          ) : (
            <div className="space-y-3">
              {currentCorrections.slice(-3).map((corr, idx) => (
                <div key={idx} className="bg-[#1b1c26] border border-red-500/10 rounded-xl p-4 space-y-2">
                  <div className="text-xs leading-relaxed">
                    <span className="text-gray-400 font-bold block text-[10px] uppercase tracking-wider mb-1">Original:</span>
                    <span className="line-through text-red-400 bg-red-950/20 px-2 py-0.5 rounded font-medium">{corr.original}</span>
                  </div>
                  <div className="text-xs leading-relaxed">
                    <span className="text-indigo-400 font-bold block text-[10px] uppercase tracking-wider mb-1">Better Version:</span>
                    <span className="text-green-400 bg-green-950/20 px-2 py-0.5 rounded font-bold">{corr.corrected}</span>
                  </div>
                  <p className="text-[11px] text-gray-400 mt-1 pl-2 border-l border-primary/30 italic">
                    "{corr.explanation}"
                  </p>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Alternative Phrasings */}
        <div>
          <h3 className="text-sm font-bold text-gray-300 flex items-center gap-2 mb-3">
            <Lightbulb className="w-4 h-4 text-primary" />
            Natural Suggestions
          </h3>
          {currentSuggestions.length === 0 ? (
            <div className="bg-[#131622] rounded-2xl p-4 text-center border border-gray-900">
              <p className="text-xs text-gray-400">Suggestions will appear here as the conversation develops.</p>
            </div>
          ) : (
            <ul className="space-y-2.5">
              {currentSuggestions.slice(-3).map((sug, idx) => (
                <li key={idx} className="bg-[#131622] border border-gray-800/80 rounded-xl p-3 flex gap-2 text-xs text-gray-300">
                  <BookOpen className="w-4 h-4 text-indigo-400 shrink-0 mt-0.5" />
                  <span>{sug}</span>
                </li>
              ))}
            </ul>
          )}
        </div>

        {/* Global Lifetime Stats */}
        {analytics && (
          <div className="pt-4 border-t border-gray-800/80">
            <h3 className="text-sm font-bold text-gray-300 mb-3">Lifetime Learning History</h3>
            <div className="grid grid-cols-2 gap-4">
              <div className="bg-[#131622] rounded-xl p-3 text-center border border-gray-900">
                <span className="text-[10px] text-gray-500 font-bold uppercase tracking-wider">Total Conversations</span>
                <span className="block text-xl font-extrabold text-white mt-1">{analytics.total_sessions}</span>
              </div>
              <div className="bg-[#131622] rounded-xl p-3 text-center border border-gray-900">
                <span className="text-[10px] text-gray-500 font-bold uppercase tracking-wider">Words Transcribed</span>
                <span className="block text-xl font-extrabold text-white mt-1">{analytics.total_user_messages}</span>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
