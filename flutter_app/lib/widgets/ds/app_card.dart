import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// 파스텔 **서피스 카드** — Routine Add 섹션, Progress 카드 등
enum AppCardVariant {
  /// 반투명 흰 배경 + 얇은 보더 (폼 섹션)
  standard,

  /// 조금 더 떠 보이는 흰 카드 (진행률 헤더 등)
  elevated,
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.standard,
    this.padding,
    this.margin,
  });

  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final pad = padding ?? const EdgeInsets.all(AppSpacing.cardPadding);

    return Container(
      width: double.infinity,
      margin: margin,
      padding: pad,
      decoration: BoxDecoration(
        color: variant == AppCardVariant.elevated
            ? Colors.white.withValues(alpha: 0.88)
            : Colors.white.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(
          variant == AppCardVariant.elevated
              ? AppRadii.cardLarge
              : AppRadii.card,
        ),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textMuted.withValues(
                alpha: variant == AppCardVariant.elevated ? 0.14 : 0.08),
            blurRadius: variant == AppCardVariant.elevated ? 28 : 16,
            offset: Offset(0, variant == AppCardVariant.elevated ? 10 : 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
