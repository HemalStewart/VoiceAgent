import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/voice_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/siri_orb.dart';
import '../widgets/waveform_visualizer.dart';
import '../widgets/speaking_bars.dart';
import '../widgets/persona_selector.dart';
import '../widgets/mode_selector.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _showTextInput = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      final voice = context.read<VoiceProvider>();
      voice.ensureSession(
        persona: settings.selectedPersona,
        mode: settings.selectedMode,
      );
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleMicTap(VoiceProvider voice, SettingsProvider settings) async {
    HapticFeedback.mediumImpact();
    if (voice.isRecording) {
      await voice.stopAndSubmitRecording(
        persona: settings.selectedPersona,
        mode: settings.selectedMode,
      );
    } else {
      await voice.startRecording();
    }
  }

  void _submitTextMessage(VoiceProvider voice, SettingsProvider settings) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    setState(() => _showTextInput = false);
    voice.sendTextMessage(
      text,
      persona: settings.selectedPersona,
      mode: settings.selectedMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EnglishMind',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'AI Spoken Tutor',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Connection status pill
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: settings.isConnected ? AppColors.accent : AppColors.errorText,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: settings.isConnected ? AppColors.accent : AppColors.errorText,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    settings.isConnected ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: settings.isConnected ? AppColors.accent : AppColors.errorText,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Selectors Bar: Tutor Persona + Lesson Mode
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Tutor Selector
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        PersonaSelectorSheet.show(
                          context,
                          currentPersona: settings.selectedPersona,
                          onSelect: (persona) {
                            settings.setPersona(persona);
                            voice.startNewSession(
                              persona: persona,
                              mode: settings.selectedMode,
                            );
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Text(settings.selectedPersona.flag, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TUTOR',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    settings.selectedPersona.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textMuted, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Mode Selector
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        ModeSelectorSheet.show(
                          context,
                          currentMode: settings.selectedMode,
                          onSelect: (mode) {
                            settings.setMode(mode);
                            voice.startNewSession(
                              persona: settings.selectedPersona,
                              mode: mode,
                            );
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Text(settings.selectedMode.icon, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'MODE',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    settings.selectedMode.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textMuted, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Interactive Tutor Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Dynamic Siri Orb Avatar
                    Center(
                      child: SiriOrb(
                        isThinking: voice.isThinking,
                        isPlaying: voice.isPlaying,
                        isRecording: voice.isRecording,
                        amplitude: voice.currentAmplitude,
                        size: 150,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Visualizer / Audio Waves
                    if (voice.isRecording) ...[
                      WaveformVisualizer(
                        amplitude: voice.currentAmplitude,
                        isRecording: voice.isRecording,
                      ),
                      const SizedBox(height: 16),
                    ] else if (voice.isPlaying) ...[
                      const SpeakingBars(height: 40),
                      const SizedBox(height: 16),
                    ],

                    // State Status Text
                    Text(
                      voice.isThinking
                          ? 'Tutor is thinking...'
                          : (voice.isPlaying
                              ? '${settings.selectedPersona.name} is speaking...'
                              : (voice.isRecording ? 'Listening to your voice...' : 'Ready to talk')),
                      style: TextStyle(
                        color: voice.isRecording
                            ? AppColors.secondary
                            : (voice.isThinking ? AppColors.primary : AppColors.textSecondary),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Transcript or Last Message Preview
                    if (voice.currentTranscript.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          '"${voice.currentTranscript}"',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    // Error Message (if any)
                    if (voice.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.errorBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.errorText.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.errorText, size: 16),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                voice.errorMessage!,
                                style: const TextStyle(color: AppColors.errorText, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Optional Text Input Box
            if (_showTextInput)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Type your message in English...',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          filled: true,
                          fillColor: AppColors.card,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                        onSubmitted: (_) => _submitTextMessage(voice, settings),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                      onPressed: () => _submitTextMessage(voice, settings),
                    ),
                  ],
                ),
              ),

            // Primary Voice Controls & Action Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Text input toggle
                  IconButton(
                    icon: Icon(
                      _showTextInput ? Icons.keyboard_hide_rounded : Icons.keyboard_rounded,
                      color: _showTextInput ? AppColors.primary : AppColors.textSecondary,
                    ),
                    tooltip: 'Type message',
                    onPressed: () {
                      setState(() => _showTextInput = !_showTextInput);
                    },
                  ),

                  // Big Center Mic Button
                  GestureDetector(
                    onTap: voice.isThinking
                        ? null
                        : () => _handleMicTap(voice, settings),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: voice.isRecording ? AppColors.secondary : AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: (voice.isRecording ? AppColors.secondary : AppColors.primary)
                                .withValues(alpha: 0.4),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          voice.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),

                  // Stop Playback or Replay button
                  IconButton(
                    icon: Icon(
                      voice.isPlaying ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
                      color: voice.isPlaying ? AppColors.secondary : AppColors.textSecondary,
                    ),
                    tooltip: voice.isPlaying ? 'Stop voice' : 'Listen',
                    onPressed: () {
                      if (voice.isPlaying) {
                        voice.stopPlayback();
                      } else if (voice.messages.isNotEmpty) {
                        final tutorMsgs = voice.messages.where((m) => m.isAssistant);
                        if (tutorMsgs.isNotEmpty) {
                          voice.playMessageAudio(
                            tutorMsgs.last,
                            personaId: settings.selectedPersona.id,
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
