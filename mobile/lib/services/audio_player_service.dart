import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();

  final StreamController<bool> _playbackStateController = StreamController<bool>.broadcast();
  Stream<bool> get playbackStateStream => _playbackStateController.stream;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  AudioPlayerService() {
    _init();
  }

  void _init() {
    // Setup AudioPlayer listener
    _audioPlayer.onPlayerStateChanged.listen((state) {
      final playing = state == PlayerState.playing;
      if (_isPlaying != playing) {
        _isPlaying = playing;
        _playbackStateController.add(playing);
      }
    });

    // Setup FlutterTTS listeners
    _flutterTts.setStartHandler(() {
      _isPlaying = true;
      _playbackStateController.add(true);
    });

    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
      _playbackStateController.add(false);
    });

    _flutterTts.setErrorHandler((_) {
      _isPlaying = false;
      _playbackStateController.add(false);
    });
  }

  /// Play tutor audio directly from base64 WAV payload returned by backend
  Future<bool> playBase64Audio(String base64Wav) async {
    try {
      await stop();
      final bytes = base64Decode(base64Wav);
      await _audioPlayer.play(BytesSource(bytes));
      return true;
    } catch (e) {
      debugPrint('Failed to play base64 audio: $e');
      return false;
    }
  }

  /// Play audio from remote URL (e.g. static file on backend)
  Future<bool> playUrlAudio(String url) async {
    try {
      await stop();
      await _audioPlayer.play(UrlSource(url));
      return true;
    } catch (e) {
      debugPrint('Failed to play URL audio: $e');
      return false;
    }
  }

  /// Play audio via local device TTS (Fallback if Kokoro/Cloud audio is empty or in text mode)
  Future<void> speakText(String text, {required String personaId}) async {
    try {
      await stop();

      // Configure accent and rate based on tutor persona
      if (personaId.toLowerCase() == 'emma') {
        await _flutterTts.setLanguage('en-GB');
        await _flutterTts.setPitch(1.05);
      } else if (personaId.toLowerCase() == 'alex') {
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.setPitch(0.95);
      } else {
        // Sophia
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.setPitch(1.0);
      }

      await _flutterTts.setSpeechRate(0.48); // Slightly measured cadence for learners
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
      _isPlaying = false;
      _playbackStateController.add(false);
    }
  }

  /// Stop any active audio playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      await _flutterTts.stop();
      _isPlaying = false;
      _playbackStateController.add(false);
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
    _playbackStateController.close();
  }
}
