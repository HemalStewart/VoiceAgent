import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/session.dart';
import '../models/message.dart';
import '../models/analytics.dart';
import 'storage_service.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse.success(this.data) : success = true, error = null;
  ApiResponse.failure(this.error) : success = false, data = null;
}

class ProcessSpeechResult {
  final String userTranscript;
  final String tutorReply;
  final List<dynamic> corrections;
  final List<String> suggestions;
  final List<String> pronunciationTargets;
  final String cefrEstimate;
  final String tutorAudioBase64;
  final String? tutorAudioUrl;

  ProcessSpeechResult({
    required this.userTranscript,
    required this.tutorReply,
    required this.corrections,
    required this.suggestions,
    required this.pronunciationTargets,
    required this.cefrEstimate,
    required this.tutorAudioBase64,
    this.tutorAudioUrl,
  });

  factory ProcessSpeechResult.fromJson(Map<String, dynamic> json) {
    return ProcessSpeechResult(
      userTranscript: json['user_transcript'] as String? ?? '',
      tutorReply: json['tutor_reply'] as String? ?? '',
      corrections: (json['corrections'] as List?) ?? [],
      suggestions: ((json['suggestions'] as List?) ?? []).map((s) => s.toString()).toList(),
      pronunciationTargets: ((json['pronunciation_targets'] as List?) ?? []).map((p) => p.toString()).toList(),
      cefrEstimate: json['cefr_estimate'] as String? ?? 'B1',
      tutorAudioBase64: json['tutor_audio_base64'] as String? ?? '',
      tutorAudioUrl: json['tutor_audio_url'] as String?,
    );
  }
}

class ApiService {
  final StorageService _storageService;

  ApiService({StorageService? storageService})
      : _storageService = storageService ?? StorageService();

  Future<String> _baseUrl() => _storageService.getBaseUrl();

  /// Check health and configuration of backend
  Future<ApiResponse<Map<String, dynamic>>> checkHealth() async {
    try {
      final base = await _baseUrl();
      final uri = Uri.parse('$base/api/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return ApiResponse.success(jsonDecode(response.body) as Map<String, dynamic>);
      }
      return ApiResponse.failure('Server returned code ${response.statusCode}');
    } catch (e) {
      return ApiResponse.failure('Could not connect to backend server: $e');
    }
  }

  /// Start a new tutoring session
  Future<ApiResponse<Session>> startSession({
    required String persona,
    required String mode,
  }) async {
    try {
      final base = await _baseUrl();
      final uri = Uri.parse('$base/api/sessions');
      final response = await http.post(
        uri,
        body: {'persona': persona, 'mode': mode},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(Session.fromJson(data));
      }
      return ApiResponse.failure('Failed to create session: HTTP ${response.statusCode}');
    } catch (e) {
      return ApiResponse.failure('Network error: $e');
    }
  }

  /// Get conversation history for a session
  Future<ApiResponse<List<Message>>> getSessionHistory(String sessionId) async {
    try {
      final base = await _baseUrl();
      final uri = Uri.parse('$base/api/sessions/$sessionId/history');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawHistory = data['history'] as List? ?? [];
        final messages = rawHistory
            .map((m) => Message.fromJson(m as Map<String, dynamic>, baseUrl: base))
            .toList();
        return ApiResponse.success(messages);
      }
      return ApiResponse.failure('Failed to fetch history');
    } catch (e) {
      return ApiResponse.failure('Network error: $e');
    }
  }

  /// Process voice audio (multipart file upload to /api/process-audio)
  Future<ApiResponse<ProcessSpeechResult>> processAudio({
    required String sessionId,
    required String filePath,
    Uint8List? fileBytes,
  }) async {
    try {
      final base = await _baseUrl();
      final uri = Uri.parse('$base/api/process-audio');

      final request = http.MultipartRequest('POST', uri);
      request.fields['session_id'] = sessionId;

      if (fileBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'audio',
          fileBytes,
          filename: 'recording.wav',
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'audio',
          filePath,
          filename: 'recording.wav',
        ));
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(ProcessSpeechResult.fromJson(data));
      } else {
        String errorMsg = 'Failed to process speech (HTTP ${response.statusCode})';
        try {
          final errJson = jsonDecode(response.body);
          if (errJson['detail'] != null) errorMsg = errJson['detail'];
        } catch (_) {}
        return ApiResponse.failure(errorMsg);
      }
    } catch (e) {
      return ApiResponse.failure('Audio transmission error: $e');
    }
  }

  /// Process text message (alternative text endpoint /api/process-text)
  Future<ApiResponse<ProcessSpeechResult>> processText({
    required String sessionId,
    required String text,
  }) async {
    try {
      final base = await _baseUrl();
      final uri = Uri.parse('$base/api/process-text');
      final response = await http.post(
        uri,
        body: {'session_id': sessionId, 'text': text},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(ProcessSpeechResult.fromJson(data));
      } else {
        String errorMsg = 'Failed to process message (HTTP ${response.statusCode})';
        try {
          final errJson = jsonDecode(response.body);
          if (errJson['detail'] != null) errorMsg = errJson['detail'];
        } catch (_) {}
        return ApiResponse.failure(errorMsg);
      }
    } catch (e) {
      return ApiResponse.failure('Text transmission error: $e');
    }
  }

  /// Retrieve analytics data
  Future<ApiResponse<Analytics>> getAnalytics() async {
    try {
      final base = await _baseUrl();
      final uri = Uri.parse('$base/api/analytics');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(Analytics.fromJson(data));
      }
      return ApiResponse.failure('Failed to load analytics');
    } catch (e) {
      return ApiResponse.failure('Analytics network error: $e');
    }
  }
}
