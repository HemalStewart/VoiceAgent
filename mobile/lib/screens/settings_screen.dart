import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/voice_provider.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _urlController = TextEditingController(text: settings.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _saveUrl(SettingsProvider settings) {
    settings.setBaseUrl(_urlController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Server URL updated. Checking connection...'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final voice = context.watch<VoiceProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings & Backend'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Backend Connection Status Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: settings.isConnected ? AppColors.accent : AppColors.errorText,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: settings.isConnected ? AppColors.accent : AppColors.errorText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        settings.isConnected
                            ? 'Backend Connected'
                            : 'Backend Disconnected / Unreachable',
                        style: TextStyle(
                          color: settings.isConnected ? AppColors.accent : AppColors.errorText,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    settings.isConnected
                        ? 'Successfully communicating with FastAPI speech & AI pipeline.'
                        : (settings.connectionError ?? 'Ensure your backend server is running.'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: settings.isCheckingConnection
                        ? null
                        : () => settings.checkConnection(),
                    icon: settings.isCheckingConnection
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Test Connection'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Server URL Configuration
            const Text(
              'Backend Server URL',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Configure the HTTP address where your Python FastAPI backend is hosted.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'http://localhost:8000',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _saveUrl(settings),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick Preset Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  backgroundColor: AppColors.card,
                  label: const Text('Android: 10.0.2.2:8000', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  onPressed: () {
                    _urlController.text = 'http://10.0.2.2:8000';
                    _saveUrl(settings);
                  },
                ),
                ActionChip(
                  backgroundColor: AppColors.card,
                  label: const Text('iOS / Mac: localhost:8000', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  onPressed: () {
                    _urlController.text = 'http://localhost:8000';
                    _saveUrl(settings);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Server Pipeline Info
            if (settings.serverHealthInfo != null) ...[
              const Text(
                'Active AI Pipeline Components',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Operating Mode', settings.serverHealthInfo!['mode']?.toString().toUpperCase() ?? 'CLOUD'),
                    const Divider(color: AppColors.cardBorder, height: 20),
                    _buildInfoRow('Speech-to-Text', settings.serverHealthInfo!['local_models']?['whisper'] ?? 'Whisper ASR'),
                    const Divider(color: AppColors.cardBorder, height: 20),
                    _buildInfoRow('Language Model', settings.serverHealthInfo!['local_models']?['llm'] ?? 'Groq / Qwen / GPT'),
                    const Divider(color: AppColors.cardBorder, height: 20),
                    _buildInfoRow('Text-to-Speech', settings.serverHealthInfo!['local_models']?['tts_voice'] ?? 'Kokoro-82M Voice'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Active Session Management
            const Text(
              'Session Management',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Session ID', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      Text(
                        voice.sessionId != null ? '${voice.sessionId!.substring(0, 8)}...' : 'None',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () {
                      voice.startNewSession(
                        persona: settings.selectedPersona,
                        mode: settings.selectedMode,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Started a new conversation session'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('Start New Session'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // App Version Footer
            const Center(
              child: Text(
                'EnglishMind Mobile v1.0.0\n100% Private, Low-Latency Spoken English Learning',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
