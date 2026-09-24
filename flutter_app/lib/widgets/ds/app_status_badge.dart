import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_pixel_style.dart';
import '../../theme/app_theme_preset.dart';

enum AppStatusBadgeTone {
  neutral,

  /// '진행 중'처럼 지금 벌어지는 일. 시안은 이것만 보라 단색으로 채운다.
  info,

  /// 반복 주기 같은 곁들이 정보. 예전 info의 연한 톤을 이어받는다.
  meta,
  success,
  warning,
  readySoon,
}

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = AppStatusBadgeTone.neutral,
    this.compact = false,
  });

  final String label;
  final AppStatusBadgeTone tone;

  /// 본문 줄 안에 끼는 작은 칩. 설명 글자와 높이를 맞춘다.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = _schemeForTone(context, tone);
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 1)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        color: scheme.$1,
        shape: AppPixelStyle.shape(color: scheme.$2, steps: 1),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.captionTight.copyWith(
          fontSize: compact ? 11 : null,
          fontWeight: FontWeight.w700,
          color: scheme.$3,
        ),
      ),
    );
  }

  (Color, Color, Color) _schemeForTone(
    BuildContext context,
    AppStatusBadgeTone tone,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    switch (tone) {
      case AppStatusBadgeTone.neutral:
        return (
          AppColors.orbitSurfaceSoft.withValues(alpha: 0.8),
          AppColors.orbitBorder.withValues(alpha: 0.8),
          AppColors.textMuted,
        );
      case AppStatusBadgeTone.info:
        // 흰 글자와 5.66:1. 지금 벌어지는 일이 가장 강하게 읽혀야 한다.
        return (
          primary,
          primary,
          Colors.white,
        );
      case AppStatusBadgeTone.meta:
        return (
          context.appTheme.preset.selectedSurface.withValues(alpha: 0.34),
          primary.withValues(alpha: 0.18),
          primary,
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
          AppColors.readySoonText,
        );
    }
  }
}
