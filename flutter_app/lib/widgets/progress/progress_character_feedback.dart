import 'package:flutter/material.dart';
import '../../models/progress_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// 하단 상태 피드백 카드
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
            Colors.white.withValues(alpha: 0.9),
            AppColors.orbitSurfaceSoft.withValues(alpha: 0.76),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.orbitBorder.withValues(alpha: 0.94),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.orbitPrimary.withValues(alpha: 0.08),
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
              gradient: AppColors.orbitPrimaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orbitPrimary.withValues(alpha: 0.24),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                content.titleEmoji,
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
                    Text(
                      content.title,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  content.message,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content.subMessage,
                  style: AppTextStyles.captionTight.copyWith(
                    fontSize: 12,
                    color: AppColors.textMuted.withValues(alpha: 0.95),
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
