import 'correction.dart';

class Message {
  final String? messageId;
  final String role; // 'user' or 'assistant'
  final String content;
  final String? audioPath;
  final List<Correction> grammarCorrections;
  final List<String> suggestions;
  final List<String> pronunciationTargets;
  final String? cefrEstimate;
  final DateTime createdAt;

  Message({
    this.messageId,
    required this.role,
    required this.content,
    this.audioPath,
    this.grammarCorrections = const [],
    this.suggestions = const [],
    this.pronunciationTargets = const [],
    this.cefrEstimate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory Message.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
    List<Correction> corrections = [];
    if (json['grammar_corrections'] != null) {
      if (json['grammar_corrections'] is List) {
        corrections = (json['grammar_corrections'] as List)
            .map((c) => Correction.fromJson(c as Map<String, dynamic>))
            .toList();
      }
    }

    List<String> suggestions = [];
    if (json['suggestions'] != null && json['suggestions'] is List) {
      suggestions = (json['suggestions'] as List).map((s) => s.toString()).toList();
    }

    List<String> pronunciationTargets = [];
    if (json['pronunciation_targets'] != null && json['pronunciation_targets'] is List) {
      pronunciationTargets = (json['pronunciation_targets'] as List).map((p) => p.toString()).toList();
    }

    String? audio = json['audio_path'] as String?;
    if (audio != null && baseUrl != null && audio.startsWith('/')) {
      audio = '$baseUrl$audio';
    }

    DateTime created;
    try {
      created = json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now();
    } catch (_) {
      created = DateTime.now();
    }

    return Message(
      messageId: json['message_id'] as String?,
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      audioPath: audio,
      grammarCorrections: corrections,
      suggestions: suggestions,
      pronunciationTargets: pronunciationTargets,
      cefrEstimate: json['cefr_estimate'] as String?,
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (messageId != null) 'message_id': messageId,
      'role': role,
      'content': content,
      'audio_path': audioPath,
      'grammar_corrections': grammarCorrections.map((c) => c.toJson()).toList(),
      'suggestions': suggestions,
      'pronunciation_targets': pronunciationTargets,
      'cefr_estimate': cefrEstimate,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
