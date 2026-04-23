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
    final isElevated = variant == AppCardVariant.elevated;

    return Container(
      width: double.infinity,
      margin: margin,
      padding: pad,
      decoration: BoxDecoration(
        gradient: isElevated
            ? AppColors.orbitCardGradient
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.82),
                  AppColors.orbitSurface.withValues(alpha: 0.78),
                ],
              ),
        borderRadius: BorderRadius.circular(
          isElevated ? AppRadii.cardLarge : AppRadii.card,
        ),
        border: Border.all(
          color: (isElevated ? AppColors.orbitBorder : AppColors.border)
              .withValues(alpha: isElevated ? 0.85 : 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.orbitPrimary
                .withValues(alpha: isElevated ? 0.08 : 0.04),
            blurRadius: isElevated ? 28 : 16,
            offset: Offset(0, isElevated ? 12 : 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
