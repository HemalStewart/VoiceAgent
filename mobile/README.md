# EnglishMind AI - Flutter Mobile App

A companion mobile application for **EnglishMind AI** built with Flutter and Dart. Supports iOS, Android, and macOS desktop with real-time voice capture, interactive Siri-like audio visualizers, speech synthesis playback, and instant CEFR & grammar feedback.

---

## Features

- **Tutor Personas**:
  - **Emma** (🇬🇧 British RP Accent) - Warm, polite conversational English
  - **Alex** (🇺🇸 American Accent) - Energetic, idioms, casual phrasing
  - **Sophia** (💼 Business English) - Professional vocabulary, interviews & meetings
- **Lesson Modes**: Free Conversation, Guided Discussion, IELTS Speaking Prep, and Scenario Roleplay.
- **Voice Pipeline**:
  - High-fidelity microphone recording with 16kHz WAV encoding.
  - Real-time dynamic audio waveform amplitude visualizer.
  - Animated Siri-like morphing breathing orb for Thinking, Listening, and Speaking states.
  - Jumping equalizer audio bars during tutor voice playback.
- **Speech Synthesis Playback**:
  - Direct playback of tutor voice synthesized by Kokoro-82M / Cloud TTS.
  - Native offline TTS fallback (`flutter_tts`) when offline or in text mode.
  - Tap-to-replay tutor voice for any historical message.
  - Word-level pronunciation practice targets.
- **Grammar & Fluency Feedback**:
  - Instant grammar improvements card (original mistake with strikethrough, corrected phrasing, and explanation).
  - Alternative idiomatic phrasing suggestions.
  - Real-time CEFR Fluency Ranking badge (A1, A2, B1, B2, C1, C2).
  - Global lifetime analytics and progression charts.
- **Network & Backend Integration**:
  - Connects to FastAPI backend via configurable server URL.
  - Smart presets for Android Emulator (`http://10.0.2.2:8000`), iOS Simulator / Mac (`http://localhost:8000`), or LAN IP for physical phones.
  - Real-time backend connection status and health monitoring.

---

## Getting Started

### 1. Prerequisites

- Flutter SDK (>= 3.11.4)
- Python FastAPI backend running (`./start.sh` or `python -m backend.app`)

### 2. Install Dependencies

```bash
cd mobile
flutter pub get
```

### 3. Run the App

#### iOS Simulator:
```bash
flutter run -d iPhone
```

#### Android Emulator:
```bash
flutter run -d emulator
```

#### macOS Desktop:
```bash
flutter run -d macos
```

#### Physical Device over Wi-Fi / USB:
1. Find your computer's local IP address (e.g. macOS Network Settings -> `192.168.1.xxx`).
2. Run `flutter run`.
3. In the mobile app, tap the **Settings** tab and enter `http://<YOUR_LAN_IP>:8000`. Tap **Save** and **Test Connection**.

---

## Project Structure

```
mobile/lib/
├── main.dart                      # Application entrypoint & bottom navigation
├── theme/
│   ├── app_colors.dart            # Design tokens & color palette
│   └── app_theme.dart             # Dark theme definition
├── models/
│   ├── session.dart               # Session metadata
│   ├── message.dart               # Chat message & corrections
│   ├── correction.dart            # Grammar correction item
│   ├── tutor_persona.dart         # Emma, Alex, Sophia definitions
│   ├── lesson_mode.dart           # Free Chat, Guided, IELTS, Roleplay
│   └── analytics.dart             # Analytics & CEFR distributions
├── services/
│   ├── api_service.dart           # FastAPI REST & multipart audio client
│   ├── audio_recorder_service.dart# Microphone recording & amplitude stream
│   ├── audio_player_service.dart  # Kokoro/Cloud audio playback & TTS fallback
│   └── storage_service.dart       # Preferences & server URL storage
├── providers/
│   ├── voice_provider.dart        # Voice recording, state & chat provider
│   └── settings_provider.dart     # Backend connection & tutor configurations
├── widgets/
│   ├── siri_orb.dart              # Siri-like breathing glowing tutor orb
│   ├── waveform_visualizer.dart   # Live microphone waveform visualizer
│   ├── speaking_bars.dart         # Jumping equalizer playback bars
│   ├── cefr_badge.dart            # CEFR rank badge
│   ├── grammar_correction_card.dart# Strikethrough vs corrected card
│   ├── message_bubble.dart        # Chat bubble with pronunciation targets
│   ├── persona_selector.dart      # Tutor selection bottom sheet
│   └── mode_selector.dart         # Practice mode bottom sheet
└── screens/
    ├── home_screen.dart           # Main voice workspace & avatar
    ├── transcript_screen.dart     # Conversation chat transcript
    ├── feedback_screen.dart       # Grammar corrections & analytics
    └── settings_screen.dart       # Server URL & pipeline health
```

---

## Permissions Configured

- **iOS** (`ios/Runner/Info.plist`):
  - `NSMicrophoneUsageDescription`: Microphone access for speech practice.
  - `NSSpeechRecognitionUsageDescription`: Speech transcription.
  - `NSAppTransportSecurity` (Allows arbitrary loads for local HTTP backend development).
- **Android** (`android/app/src/main/AndroidManifest.xml`):
  - `android.permission.RECORD_AUDIO`
  - `android.permission.INTERNET`
  - `android.permission.MODIFY_AUDIO_SETTINGS`
  - `android:usesCleartextTraffic="true"` (for local HTTP servers like `10.0.2.2:8000`).
- **macOS** (`macos/Runner/DebugProfile.entitlements`, `Release.entitlements`, `Info.plist`):
  - `com.apple.security.device.audio-input`
  - `com.apple.security.network.client`
