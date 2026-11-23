class Session {
  final String sessionId;
  final String persona;
  final String mode;
  final String createdAt;

  Session({
    required this.sessionId,
    required this.persona,
    required this.mode,
    required this.createdAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      sessionId: json['session_id'] as String? ?? '',
      persona: json['persona'] as String? ?? 'emma',
      mode: json['mode'] as String? ?? 'free_chat',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
