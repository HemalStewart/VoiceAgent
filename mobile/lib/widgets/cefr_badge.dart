import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CefrBadge extends StatelessWidget {
  final String level;
  final double size;
  final bool showDescription;

  const CefrBadge({
    super.key,
    required this.level,
    this.size = 48.0,
    this.showDescription = false,
  });

  static const Map<String, String> cefrDescriptions = {
    'A1': 'Beginner: Basic everyday phrases',
    'A2': 'Elementary: Simple routine tasks',
    'B1': 'Intermediate: Conversational fluency',
    'B2': 'Upper Intermediate: Complex discussions',
    'C1': 'Advanced: Fluent & spontaneous speech',
    'C2': 'Mastery: Native-level precision',
  };

  @override
  Widget build(BuildContext context) {
    final color = AppColors.cefrColors[level.toUpperCase()] ?? AppColors.primary;

    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          level.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );

    if (!showDescription) return badge;

    return Row(
      children: [
        badge,
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CEFR Level ${level.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                cefrDescriptions[level.toUpperCase()] ?? 'Proficiency ranking',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
