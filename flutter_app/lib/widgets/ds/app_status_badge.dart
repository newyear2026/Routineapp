import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

enum AppStatusBadgeTone { neutral, info, success, warning, readySoon }

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = AppStatusBadgeTone.neutral,
  });

  final String label;
  final AppStatusBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = _schemeForTone(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.$1,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.$2),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionTight.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.$3,
        ),
      ),
    );
  }

  (Color, Color, Color) _schemeForTone(AppStatusBadgeTone tone) {
    switch (tone) {
      case AppStatusBadgeTone.neutral:
        return (
          AppColors.textMuted.withValues(alpha: 0.12),
          AppColors.textMuted.withValues(alpha: 0.18),
          AppColors.textMuted,
        );
      case AppStatusBadgeTone.info:
        return (
          const Color(0xFFD4E4FF).withValues(alpha: 0.45),
          const Color(0xFFB5CBEF),
          const Color(0xFF4A648F),
        );
      case AppStatusBadgeTone.success:
        return (
          AppColors.success.withValues(alpha: 0.18),
          AppColors.success.withValues(alpha: 0.4),
          const Color(0xFF3F7A4A),
        );
      case AppStatusBadgeTone.warning:
        return (
          const Color(0xFFFFE9D4).withValues(alpha: 0.65),
          const Color(0xFFF0CAA8),
          const Color(0xFF8C6947),
        );
      case AppStatusBadgeTone.readySoon:
        return (
          AppColors.accentLavender.withValues(alpha: 0.18),
          AppColors.accentLavender.withValues(alpha: 0.36),
          const Color(0xFF6D5D86),
        );
    }
  }
}
