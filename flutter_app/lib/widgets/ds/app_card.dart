import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_pixel_style.dart';

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
    // radius는 기존 호출부 호환용이다. 공통 카드는 직각으로 통일한다.
    borderRadius: AppPixelStyle.radius,
    border: Border.all(
      color: borderColor ?? AppPixelStyle.outline,
      width: AppPixelStyle.borderWidth,
    ),
    boxShadow: [
      BoxShadow(
        color: AppPixelStyle.shadow,
        offset: elevated ? AppPixelStyle.heroOffset : AppPixelStyle.cardOffset,
      ),
    ],
  );
}

/// 픽셀 서피스 카드 — Routine Add 섹션, Progress 카드 등
enum AppCardVariant {
  /// 흰 배경 + 직각 테두리 + 단단한 그림자 (폼 섹션)
  standard,

  /// 그림자 깊이를 늘린 흰 카드 (진행률 헤더 등)
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
      decoration: appSurfaceDecoration(elevated: isElevated),
      child: child,
    );
  }
}
