import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_text_styles.dart';

/// 하위 호환: 기존 코드의 `HomeTheme.xxx` 참조 유지.
///
/// 신규 코드는 [AppColors], [AppSpacing], [AppRadii], [AppTextStyles], [AppLayout] 사용을 권장합니다.
abstract final class HomeTheme {
  static const LinearGradient pageGradient = AppColors.pageGradient;
  static const LinearGradient shellGradient = AppColors.shellGradient;

  static const Color textPrimary = AppColors.textPrimary;
  static const Color textMuted = AppColors.textMuted;
  static const Color accentPink = AppColors.accentPink;
  static const Color actionBlue = AppColors.actionBlue;
  static const Color actionOrange = AppColors.actionOrange;
  static const Color actionRose = AppColors.actionRose;

  static const double mobileWidth = AppLayout.maxContentWidth;
  static const double shellRadius = AppRadii.shell;
}
