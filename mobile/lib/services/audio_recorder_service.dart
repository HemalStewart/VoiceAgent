import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  final StreamController<double> _amplitudeController = StreamController<double>.broadcast();

  String? _currentRecordingPath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  /// Check & request microphone permission
  Future<bool> checkPermission() async {
    try {
      final hasPerm = await _recorder.hasPermission();
      if (hasPerm) return true;

      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking mic permission: $e');
      return false;
    }
  }

  /// Start recording speech to a WAV file
  Future<bool> startRecording() async {
    try {
      final permitted = await checkPermission();
      if (!permitted) {
        debugPrint('Microphone permission not granted');
        return false;
      }

      if (_isRecording) {
        await stopRecording();
      }

      String path = '';
      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        path = '${tempDir.path}/user_voice_$timestamp.wav';
        _currentRecordingPath = path;
      }

      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 128000,
      );

      await _recorder.start(config, path: path);
      _isRecording = true;

      // Listen to amplitude changes for realtime waveform drawing
      _amplitudeSubscription?.cancel();
      _amplitudeSubscription = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 60))
          .listen((amp) {
        // Convert dB (-60 to 0) to normalized 0.0 -> 1.0 range
        double currentDb = amp.current;
        double normalized = (currentDb + 60.0) / 60.0;
        if (normalized.isNaN || normalized < 0.0) normalized = 0.0;
        if (normalized > 1.0) normalized = 1.0;
        _amplitudeController.add(normalized);
      });

      return true;
    } catch (e) {
      debugPrint('Error starting audio recording: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Stop recording and return the recorded file path
  Future<String?> stopRecording() async {
    try {
      _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;
      _amplitudeController.add(0.0);

      final path = await _recorder.stop();
      _isRecording = false;
      return path ?? _currentRecordingPath;
    } catch (e) {
      debugPrint('Error stopping audio recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Cancel current recording and cleanup file
  Future<void> cancelRecording() async {
    try {
      _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;
      _amplitudeController.add(0.0);

      await _recorder.stop();
      _isRecording = false;

      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Error cancelling recording: $e');
    }
  }

  void dispose() {
    _amplitudeSubscription?.cancel();
    _amplitudeController.close();
    _recorder.dispose();
  }
}
