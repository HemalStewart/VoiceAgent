enum LessonModeType { freeChat, guided, ielts, roleplay }

class LessonMode {
  final LessonModeType type;
  final String id;
  final String title;
  final String subtitle;
  final String icon;

  const LessonMode({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  static const List<LessonMode> all = [
    LessonMode(
      type: LessonModeType.freeChat,
      id: 'free_chat',
      title: 'Free Conversation',
      subtitle: 'Natural, spontaneous daily English dialogue',
      icon: '💬',
    ),
    LessonMode(
      type: LessonModeType.guided,
      id: 'guided',
      title: 'Guided Discussion',
      subtitle: 'Structured topics with vocabulary prompts',
      icon: '🧭',
    ),
    LessonMode(
      type: LessonModeType.ielts,
      id: 'ielts',
      title: 'IELTS Speaking Prep',
      subtitle: 'Part 1, 2, and 3 test simulation & scoring',
      icon: '🎯',
    ),
    LessonMode(
      type: LessonModeType.roleplay,
      id: 'roleplay',
      title: 'Scenario Roleplay',
      subtitle: 'Job interviews, cafe ordering, airports & hotels',
      icon: '🎭',
    ),
  ];

  static LessonMode fromId(String id) {
    return all.firstWhere(
      (m) => m.id == id,
      orElse: () => all.first,
    );
  }
}
