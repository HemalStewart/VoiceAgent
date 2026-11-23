import 'package:flutter/material.dart';
import '../models/correction.dart';
import '../theme/app_colors.dart';

class GrammarCorrectionCard extends StatelessWidget {
  final Correction correction;

  const GrammarCorrectionCard({super.key, required this.correction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1C26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.errorText.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original phrase (crossed out)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.errorBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Original',
                  style: TextStyle(
                    color: AppColors.errorText,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  correction.original,
                  style: const TextStyle(
                    color: AppColors.errorText,
                    fontSize: 13,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.errorText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Corrected phrase
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Better',
                  style: TextStyle(
                    color: AppColors.successText,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  correction.corrected,
                  style: const TextStyle(
                    color: AppColors.successText,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Explanation
          Container(
            padding: const EdgeInsets.only(left: 10),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            child: Text(
              '"${correction.explanation}"',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
