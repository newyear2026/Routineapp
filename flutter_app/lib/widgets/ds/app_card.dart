import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// [AppCard]와 같은 서피스를 Container/Material로 직접 만드는 화면에서 쓰는 공통 데코레이션.
///
/// 카드마다 그림자 알파를 따로 적어 톤이 어긋나는 것을 막는다.
BoxDecoration appSurfaceDecoration({
  double radius = AppRadii.card,
  bool elevated = false,
  Color? color,
  Color? borderColor,
}) {
  return BoxDecoration(
    color: color ?? AppColors.orbitSurface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? AppColors.orbitBorder),
    boxShadow: [
      BoxShadow(
        color: AppColors.textPrimary.withValues(alpha: elevated ? 0.08 : 0.05),
        blurRadius: elevated ? 24 : 14,
        offset: Offset(0, elevated ? 10 : 6),
      ),
    ],
  );
}

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
        // 반투명 채움은 페이지 배경과 섞여 카드 경계를 지운다.
        // 불투명 서피스 + 보더로 경계를 확실히 남긴다.
        color: AppColors.orbitSurface,
        borderRadius: BorderRadius.circular(
          isElevated ? AppRadii.cardLarge : AppRadii.card,
        ),
        border: Border.all(color: AppColors.orbitBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary
                .withValues(alpha: isElevated ? 0.08 : 0.05),
            blurRadius: isElevated ? 24 : 14,
            offset: Offset(0, isElevated ? 10 : 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
