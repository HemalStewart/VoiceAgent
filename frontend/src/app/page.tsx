'use client';

import React from 'react';
import TutorWorkspace from '@/components/voice/TutorWorkspace';
import TranscriptPanel from '@/components/voice/TranscriptPanel';
import FeedbackPanel from '@/components/voice/FeedbackPanel';
import { Sparkles } from 'lucide-react';

/**
 * The practice workspace inside the Quantum shell: tutor (voice) · transcript · feedback.
 * Panels sit side by side when the canvas is wide and stack (each scrollable) when it is narrow;
 * the rail's Practice / Transcript / Feedback items jump between them.
 */
export default function Home() {
  return (
    <div className="flex min-h-0 flex-1 flex-col gap-4 p-4 @3xl:p-6 @7xl:h-full">
      <div className="grid min-h-0 flex-1 grid-cols-1 items-stretch gap-4 @4xl:grid-cols-2 @7xl:grid-cols-12 @7xl:gap-6">
        {/* Tutor workspace */}
        <section id="practice" className="flex min-h-[560px] scroll-mt-4 flex-col gap-4 @4xl:row-span-2 @7xl:col-span-5 @7xl:row-span-1 @7xl:min-h-0">
          <div className="min-h-0 flex-1">
            <TutorWorkspace />
          </div>

          {/* Quick tip */}
          <div className="glass-panel flex shrink-0 gap-3 rounded-2xl border-l-4 border-l-zinc-800 p-4">
            <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-zinc-800 text-indigo-400">
              <Sparkles className="h-4 w-4" />
            </div>
            <div>
              <h4 className="text-[11px] font-bold uppercase tracking-wider text-gray-300">Practice tip</h4>
              <p className="mt-0.5 text-[11px] leading-relaxed text-gray-400">
                Click &quot;Start Speaking&quot; and converse with your tutor. Try talking for at least 10-15 seconds to receive
                detailed feedback on your sentence structure!
              </p>
            </div>
          </div>
        </section>

        {/* Transcript */}
        <section id="transcript" className="h-[480px] min-h-0 scroll-mt-4 @7xl:col-span-4 @7xl:h-full">
          <TranscriptPanel />
        </section>

        {/* Feedback */}
        <section id="feedback" className="h-[480px] min-h-0 scroll-mt-4 @7xl:col-span-3 @7xl:h-full">
          <FeedbackPanel />
        </section>
      </div>
    </div>
  );
}
