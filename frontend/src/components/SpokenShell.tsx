"use client";

import { useCallback, useState, type ReactNode } from "react";
import { Icon, Kicker, QuantumShell, type IconName, type NavItem } from "@/quantum/ui";
import { ProfileButton, useQuantumId } from "@/quantum/id";
import { useVoiceStore } from "@/store/voiceStore";

type Mode = "free_chat" | "guided" | "ielts" | "roleplay";
type Persona = "emma" | "alex" | "sophia";

/**
 * Quantum Spoken English is one workspace (`/`) with three panels. The rail jumps between them
 * (on narrow screens they stack), and the sections panel picks the lesson mode and the teacher —
 * the same choices as the workspace's own selects, which restart the session the same way.
 */
const NAV: (NavItem & { title: string })[] = [
  { id: "practice", label: "Practice", title: "Practice", icon: "mic", href: "#practice" },
  { id: "transcript", label: "Transcript", title: "Transcript", icon: "message", href: "#transcript" },
  { id: "feedback", label: "Feedback", title: "Feedback", icon: "check", href: "#feedback" },
];

export const MODES: { id: Mode; label: string; meta: string; icon: IconName }[] = [
  { id: "free_chat", label: "Free conversation", meta: "Talk about anything", icon: "message" },
  { id: "guided", label: "Guided discussion", meta: "The tutor leads the topic", icon: "route" },
  { id: "ielts", label: "IELTS speaking", meta: "Exam-style prompts", icon: "graduation" },
  { id: "roleplay", label: "Roleplay", meta: "Job interview, café and more", icon: "users" },
];

export const PERSONAS: { id: Persona; label: string; meta: string }[] = [
  { id: "emma", label: "Emma", meta: "British RP accent" },
  { id: "alex", label: "Alex", meta: "American accent" },
  { id: "sophia", label: "Sophia", meta: "Business English" },
];

const SUGGESTIONS: Record<string, string[]> = {
  practice: ["How do I start speaking?", "Which mode should I pick?", "How long should I talk each turn?"],
  transcript: ["How do I replay what I said?", "What does 'Practice saying' mean?", "How are corrections shown?"],
  feedback: ["What does my CEFR level mean?", "How do I fix my most common mistake?", "How is my progress measured?"],
};

export default function SpokenShell({ children }: { children: ReactNode }) {
  const { signIn } = useQuantumId();
  const mode = useVoiceStore((s) => s.mode);
  const persona = useVoiceStore((s) => s.persona);
  const setMode = useVoiceStore((s) => s.setMode);
  const setPersona = useVoiceStore((s) => s.setPersona);
  const startNewSession = useVoiceStore((s) => s.startNewSession);
  const [active, setActive] = useState("practice");

  const navigate = useCallback((id: string) => {
    setActive(id);
    document.getElementById(id)?.scrollIntoView({ behavior: "smooth", block: "start" });
  }, []);

  const getContext = useCallback(() => {
    const s = useVoiceStore.getState();
    const last = [...s.messages].reverse();
    const lastUser = last.find((m) => m.role === "user");
    const lastTutor = last.find((m) => m.role === "assistant");
    return [
      `Quantum Spoken English — panel: ${NAV.find((n) => n.id === active)?.title ?? active}.`,
      `Mode: ${MODES.find((m) => m.id === s.mode)?.label ?? s.mode}. Teacher: ${PERSONAS.find((p) => p.id === s.persona)?.label ?? s.persona}.`,
      `State: ${s.isRecording ? "recording" : s.isThinking ? "tutor thinking" : s.isPlaying ? "tutor speaking" : "idle"}; ${s.messages.length} messages in this session.`,
      lastUser ? `Learner last said: "${lastUser.content.slice(0, 300)}"` : "",
      lastTutor ? `Tutor last replied: "${lastTutor.content.slice(0, 300)}"` : "",
      lastUser?.cefr_estimate ? `Latest CEFR estimate: ${lastUser.cefr_estimate}.` : "",
      lastUser?.grammar_corrections?.length
        ? `Latest corrections: ${lastUser.grammar_corrections.slice(0, 3).map((c) => `"${c.original}" → "${c.corrected}"`).join("; ")}`
        : "",
    ]
      .filter(Boolean)
      .join("\n")
      .slice(0, 1500);
  }, [active]);

  const sections = (
    <>
      <div className="q-list__group">
        <Kicker>Lesson mode</Kicker>
      </div>
      <ul className="q-list" style={{ paddingTop: 0 }}>
        {MODES.map((m) => (
          <li key={m.id}>
            <button
              type="button"
              className="q-list__item"
              aria-current={mode === m.id ? "true" : undefined}
              onClick={() => {
                if (mode === m.id) return;
                setMode(m.id);
                void startNewSession().catch(() => {});
              }}
            >
              <Icon name={m.icon} size={15} />
              <span className="q-list__text">
                <span className="q-list__title">{m.label}</span>
                <span className="q-list__meta">{m.meta}</span>
              </span>
            </button>
          </li>
        ))}
      </ul>
      <div className="q-list__group">
        <Kicker>Teacher</Kicker>
      </div>
      <ul className="q-list" style={{ paddingTop: 0 }}>
        {PERSONAS.map((p) => (
          <li key={p.id}>
            <button
              type="button"
              className="q-list__item"
              aria-current={persona === p.id ? "true" : undefined}
              onClick={() => {
                if (persona === p.id) return;
                setPersona(p.id);
                void startNewSession().catch(() => {});
              }}
            >
              <Icon name={persona === p.id ? "check" : "user"} size={15} />
              <span className="q-list__text">
                <span className="q-list__title">{p.label}</span>
                <span className="q-list__meta">{p.meta}</span>
              </span>
            </button>
          </li>
        ))}
      </ul>
    </>
  );

  return (
    <QuantumShell
      tool="spoken"
      nav={NAV}
      activeNav={active}
      onNavigate={navigate}
      sections={sections}
      sectionsTitle="Lesson"
      breadcrumb={["Practice", MODES.find((m) => m.id === mode)?.label ?? mode]}
      assistant={{ getContext, suggestions: SUGGESTIONS[active], onSignIn: signIn }}
      profile={<ProfileButton />}
    >
      {/* Container-query root: layouts use @md/@xl/@3xl (canvas width), not viewport breakpoints. */}
      <div className="@container flex min-h-0 flex-1 flex-col">{children}</div>
    </QuantumShell>
  );
}
