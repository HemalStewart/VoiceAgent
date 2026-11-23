import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/correction.dart';
import '../models/analytics.dart';
import '../models/tutor_persona.dart';
import '../models/lesson_mode.dart';
import '../services/api_service.dart';
import '../services/audio_recorder_service.dart';
import '../services/audio_player_service.dart';

class VoiceProvider extends ChangeNotifier {
  final ApiService _apiService;
  final AudioRecorderService _recorderService;
  final AudioPlayerService _playerService;

  String? _sessionId;
  bool _isRecording = false;
  bool _isThinking = false;
  bool _isPlaying = false;
  double _currentAmplitude = 0.0;
  String _currentTranscript = '';
  String? _errorMessage;

  List<Message> _messages = [];
  Analytics? _analytics;

  StreamSubscription<double>? _amplitudeSub;
  StreamSubscription<bool>? _playerStateSub;

  VoiceProvider({
    ApiService? apiService,
    AudioRecorderService? recorderService,
    AudioPlayerService? playerService,
  })  : _apiService = apiService ?? ApiService(),
        _recorderService = recorderService ?? AudioRecorderService(),
        _playerService = playerService ?? AudioPlayerService() {
    _initStreams();
  }

  String? get sessionId => _sessionId;
  bool get isRecording => _isRecording;
  bool get isThinking => _isThinking;
  bool get isPlaying => _isPlaying;
  double get currentAmplitude => _currentAmplitude;
  String get currentTranscript => _currentTranscript;
  String? get errorMessage => _errorMessage;
  List<Message> get messages => _messages;
  Analytics? get analytics => _analytics;

  String get latestCefr {
    final userMsgs = _messages.where((m) => m.isUser && m.cefrEstimate != null);
    if (userMsgs.isNotEmpty) {
      return userMsgs.last.cefrEstimate!;
    }
    return 'B1';
  }

  List<Correction> get allCorrections {
    return _messages
        .where((m) => m.isUser && m.grammarCorrections.isNotEmpty)
        .expand((m) => m.grammarCorrections)
        .toList();
  }

  List<String> get allSuggestions {
    return _messages
        .where((m) => m.isUser && m.suggestions.isNotEmpty)
        .expand((m) => m.suggestions)
        .toList();
  }

  void _initStreams() {
    _amplitudeSub = _recorderService.amplitudeStream.listen((amp) {
      _currentAmplitude = amp;
      notifyListeners();
    });

    _playerStateSub = _playerService.playbackStateStream.listen((playing) {
      if (_isPlaying != playing) {
        _isPlaying = playing;
        notifyListeners();
      }
    });
  }

  /// Initialize or ensure an active session
  Future<String?> ensureSession({
    required TutorPersona persona,
    required LessonMode mode,
  }) async {
    if (_sessionId != null) return _sessionId;
    return startNewSession(persona: persona, mode: mode);
  }

  /// Start a brand new session with selected tutor & mode
  Future<String?> startNewSession({
    required TutorPersona persona,
    required LessonMode mode,
  }) async {
    _isThinking = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.startSession(
      persona: persona.id,
      mode: mode.id,
    );

    _isThinking = false;
    if (response.success && response.data != null) {
      _sessionId = response.data!.sessionId;
      _messages = [];
      _currentTranscript = '';
      notifyListeners();
      fetchAnalytics();
      return _sessionId;
    } else {
      _errorMessage = response.error ?? 'Failed to initialize session';
      notifyListeners();
      return null;
    }
  }

  /// Start microphone recording
  Future<bool> startRecording() async {
    if (_isThinking || _isPlaying) {
      await stopPlayback();
    }

    _errorMessage = null;
    _currentTranscript = 'Listening to your voice...';
    notifyListeners();

    final started = await _recorderService.startRecording();
    if (started) {
      _isRecording = true;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Could not open microphone. Please grant audio permissions in settings.';
      _currentTranscript = '';
      _isRecording = false;
      notifyListeners();
      return false;
    }
  }

  /// Stop microphone recording & send to backend for processing
  Future<void> stopAndSubmitRecording({
    required TutorPersona persona,
    required LessonMode mode,
  }) async {
    if (!_isRecording) return;

    _isRecording = false;
    _isThinking = true;
    _currentTranscript = 'Processing your speech...';
    notifyListeners();

    final recordedPath = await _recorderService.stopRecording();

    if (recordedPath == null || !File(recordedPath).existsSync()) {
      _isThinking = false;
      _errorMessage = 'No audio captured';
      _currentTranscript = '';
      notifyListeners();
      return;
    }

    final activeSessionId = await ensureSession(persona: persona, mode: mode);
    if (activeSessionId == null) {
      _isThinking = false;
      return;
    }

    final response = await _apiService.processAudio(
      sessionId: activeSessionId,
      filePath: recordedPath,
    );

    _isThinking = false;

    if (response.success && response.data != null) {
      final result = response.data!;
      _currentTranscript = result.userTranscript;

      final corrections = result.corrections
          .map((c) => Correction.fromJson(c as Map<String, dynamic>))
          .toList();

      final userMsg = Message(
        role: 'user',
        content: result.userTranscript,
        grammarCorrections: corrections,
        suggestions: result.suggestions,
        cefrEstimate: result.cefrEstimate,
      );

      final tutorMsg = Message(
        role: 'assistant',
        content: result.tutorReply,
        pronunciationTargets: result.pronunciationTargets,
        audioPath: result.tutorAudioUrl,
      );

      _messages.add(userMsg);
      _messages.add(tutorMsg);
      notifyListeners();

      // Play synthesized tutor speech
      await _playTutorSpeech(
        base64Audio: result.tutorAudioBase64,
        audioUrl: result.tutorAudioUrl,
        tutorReply: result.tutorReply,
        personaId: persona.id,
      );

      // Refresh analytics
      fetchAnalytics();
    } else {
      _errorMessage = response.error ?? 'Failed to understand speech. Please try again.';
      _currentTranscript = '';
      notifyListeners();
    }
  }

  /// Cancel current recording without sending
  Future<void> cancelRecording() async {
    await _recorderService.cancelRecording();
    _isRecording = false;
    _currentTranscript = '';
    _currentAmplitude = 0.0;
    notifyListeners();
  }

  /// Send text input (for silent environments or quick corrections)
  Future<void> sendTextMessage(
    String text, {
    required TutorPersona persona,
    required LessonMode mode,
  }) async {
    if (text.trim().isEmpty) return;

    final activeSessionId = await ensureSession(persona: persona, mode: mode);
    if (activeSessionId == null) return;

    _isThinking = true;
    _currentTranscript = text;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.processText(
      sessionId: activeSessionId,
      text: text.trim(),
    );

    _isThinking = false;

    if (response.success && response.data != null) {
      final result = response.data!;
      final corrections = result.corrections
          .map((c) => Correction.fromJson(c as Map<String, dynamic>))
          .toList();

      final userMsg = Message(
        role: 'user',
        content: result.userTranscript,
        grammarCorrections: corrections,
        suggestions: result.suggestions,
        cefrEstimate: result.cefrEstimate,
      );

      final tutorMsg = Message(
        role: 'assistant',
        content: result.tutorReply,
        pronunciationTargets: result.pronunciationTargets,
        audioPath: result.tutorAudioUrl,
      );

      _messages.add(userMsg);
      _messages.add(tutorMsg);
      notifyListeners();

      // Read reply aloud using local TTS
      await _playerService.speakText(result.tutorReply, personaId: persona.id);

      fetchAnalytics();
    } else {
      _errorMessage = response.error ?? 'Failed to process text';
      notifyListeners();
    }
  }

  Future<void> _playTutorSpeech({
    required String base64Audio,
    required String? audioUrl,
    required String tutorReply,
    required String personaId,
  }) async {
    if (base64Audio.isNotEmpty) {
      final played = await _playerService.playBase64Audio(base64Audio);
      if (played) return;
    }

    if (audioUrl != null && audioUrl.isNotEmpty) {
      final played = await _playerService.playUrlAudio(audioUrl);
      if (played) return;
    }

    // Fallback to local TTS
    await _playerService.speakText(tutorReply, personaId: personaId);
  }

  /// Play a specific message audio or read it aloud
  Future<void> playMessageAudio(Message message, {required String personaId}) async {
    if (message.audioPath != null && message.audioPath!.isNotEmpty) {
      final played = await _playerService.playUrlAudio(message.audioPath!);
      if (played) return;
    }
    await _playerService.speakText(message.content, personaId: personaId);
  }

  /// Speak a single pronunciation target word for learner to mimic
  Future<void> speakPracticeWord(String word, {required String personaId}) async {
    await _playerService.speakText(word, personaId: personaId);
  }

  Future<void> stopPlayback() async {
    await _playerService.stop();
  }

  Future<void> fetchAnalytics() async {
    final response = await _apiService.getAnalytics();
    if (response.success && response.data != null) {
      _analytics = response.data;
      notifyListeners();
    }
  }

  void resetSession() {
    _sessionId = null;
    _messages = [];
    _currentTranscript = '';
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _amplitudeSub?.cancel();
    _playerStateSub?.cancel();
    _recorderService.dispose();
    _playerService.dispose();
    super.dispose();
  }
}
