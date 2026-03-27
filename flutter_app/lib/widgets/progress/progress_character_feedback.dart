import 'package:flutter/material.dart';
import '../../models/progress_models.dart';
import '../../theme/home_theme.dart';

/// 하단 캐릭터 피드백 카드
class ProgressFeedbackCard extends StatelessWidget {
  const ProgressFeedbackCard({
    super.key,
    required this.content,
  });

  final ProgressFeedbackContent content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFF4EB).withValues(alpha: 0.72),
            const Color(0xFFFFEFF5).withValues(alpha: 0.72),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: HomeTheme.accentPink.withValues(alpha: 0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: HomeTheme.accentPink.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE4E9), Color(0xFFFFD4E0)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: HomeTheme.accentPink.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                content.characterEmoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(content.titleEmoji,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      content.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: HomeTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  content.message,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: HomeTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content.subMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: HomeTheme.textMuted.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
