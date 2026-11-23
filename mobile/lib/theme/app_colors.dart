import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF090A0F);
  static const Color surface = Color(0xFF11131E);
  static const Color card = Color(0xFF131625);
  static const Color cardBorder = Color(0xFF1E2235);
  static const Color cardBorderActive = Color(0xFF4F46E5);

  // Accents & Brand
  static const Color primary = Color(0xFF4F46E5); // Indigo
  static const Color primaryHover = Color(0xFF4338CA);
  static const Color secondary = Color(0xFFDB2777); // Pink/Rose
  static const Color secondaryHover = Color(0xFFBE185D);
  static const Color accent = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF59E0B); // Amber

  // Text
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Chat Bubbles
  static const Color userBubble = Color(0xFF22101B);
  static const Color userBubbleBorder = Color(0x4DDB2777);
  static const Color tutorBubble = Color(0xFF121421);
  static const Color tutorBubbleBorder = Color(0x4D4F46E5);

  // Correction Badges
  static const Color errorBackground = Color(0x33EF4444);
  static const Color errorText = Color(0xFFF87171);
  static const Color successBackground = Color(0x3310B981);
  static const Color successText = Color(0xFF34D399);

  // CEFR Level Colors
  static const Map<String, Color> cefrColors = {
    'A1': Color(0xFF3B82F6), // Blue
    'A2': Color(0xFF06B6D4), // Cyan
    'B1': Color(0xFF10B981), // Emerald
    'B2': Color(0xFF8B5CF6), // Purple
    'C1': Color(0xFFEC4899), // Pink
    'C2': Color(0xFFF59E0B), // Gold
  };
}
