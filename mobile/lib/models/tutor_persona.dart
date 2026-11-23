enum TutorPersonaType { emma, alex, sophia }

class TutorPersona {
  final TutorPersonaType type;
  final String id;
  final String name;
  final String title;
  final String accent;
  final String description;
  final String avatarInitials;
  final String flag;

  const TutorPersona({
    required this.type,
    required this.id,
    required this.name,
    required this.title,
    required this.accent,
    required this.description,
    required this.avatarInitials,
    required this.flag,
  });

  static const List<TutorPersona> all = [
    TutorPersona(
      type: TutorPersonaType.emma,
      id: 'emma',
      name: 'Emma',
      title: 'Friendly British Tutor',
      accent: 'British RP',
      description: 'Warm, encouraging British teacher. Focuses on daily conversational vocabulary, polite expressions, and natural British phrasing.',
      avatarInitials: 'EM',
      flag: '🇬🇧',
    ),
    TutorPersona(
      type: TutorPersonaType.alex,
      id: 'alex',
      name: 'Alex',
      title: 'Energetic American Coach',
      accent: 'American',
      description: 'Lively, enthusiastic American coach. Focuses on idioms, modern expressions, casual phrasing, and fluent speaking.',
      avatarInitials: 'AL',
      flag: '🇺🇸',
    ),
    TutorPersona(
      type: TutorPersonaType.sophia,
      id: 'sophia',
      name: 'Sophia',
      title: 'Business English Instructor',
      accent: 'International Business',
      description: 'Professional Business instructor. Specializes in job interviews, presentations, formal negotiations, and workplace communication.',
      avatarInitials: 'SO',
      flag: '💼',
    ),
  ];

  static TutorPersona fromId(String id) {
    return all.firstWhere(
      (p) => p.id.toLowerCase() == id.toLowerCase(),
      orElse: () => all.first,
    );
  }
}
