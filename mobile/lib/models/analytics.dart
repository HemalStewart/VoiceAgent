import 'correction.dart';

class Analytics {
  final int totalSessions;
  final int totalUserMessages;
  final List<Correction> recentMistakes;
  final Map<String, int> cefrDistribution;

  Analytics({
    required this.totalSessions,
    required this.totalUserMessages,
    required this.recentMistakes,
    required this.cefrDistribution,
  });

  factory Analytics.fromJson(Map<String, dynamic> json) {
    List<Correction> mistakes = [];
    if (json['recent_mistakes'] != null && json['recent_mistakes'] is List) {
      mistakes = (json['recent_mistakes'] as List)
          .map((c) => Correction.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    Map<String, int> cefr = {};
    if (json['cefr_distribution'] != null && json['cefr_distribution'] is Map) {
      json['cefr_distribution'].forEach((k, v) {
        cefr[k.toString()] = (v as num).toInt();
      });
    }

    return Analytics(
      totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
      totalUserMessages: (json['total_user_messages'] as num?)?.toInt() ?? 0,
      recentMistakes: mistakes,
      cefrDistribution: cefr,
    );
  }
}
