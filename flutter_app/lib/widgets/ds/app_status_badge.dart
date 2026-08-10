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
          AppColors.orbitSurfaceSoft.withValues(alpha: 0.8),
          AppColors.orbitBorder.withValues(alpha: 0.8),
          AppColors.textMuted,
        );
      case AppStatusBadgeTone.info:
        return (
          AppColors.orbitHalo.withValues(alpha: 0.34),
          AppColors.orbitPrimary.withValues(alpha: 0.18),
          AppColors.orbitPrimary,
        );
      case AppStatusBadgeTone.success:
        return (
          AppColors.success.withValues(alpha: 0.18),
          AppColors.success.withValues(alpha: 0.4),
          AppColors.successText,
        );
      case AppStatusBadgeTone.warning:
        return (
          AppColors.orbitAccent.withValues(alpha: 0.2),
          AppColors.orbitAccent.withValues(alpha: 0.45),
          AppColors.scheduledText,
        );
      case AppStatusBadgeTone.readySoon:
        return (
          AppColors.orbitSecondary.withValues(alpha: 0.12),
          AppColors.orbitSecondary.withValues(alpha: 0.3),
          // orbitSecondary(#E5866B)는 밝은 배경에서 2.6:1로 본문 대비에 못 미친다.
          const Color(0xFF9C4A2F),
        );
    }
  }
}
