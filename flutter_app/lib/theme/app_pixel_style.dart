import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Sobra의 단색 서피스·직각 테두리·단단한 그림자를 루틴 앱 색상에 맞춘다.
/// 데이터나 화면 동작에는 관여하지 않는다.
abstract final class AppPixelStyle {
  static const borderWidth = 2.0;
  static const radius = BorderRadius.zero;
  static const outline = AppColors.textPrimary;
  static const shadow = Color(0x33241F31);
  static const cardOffset = Offset(3, 3);
  static const heroOffset = Offset(5, 5);
  static const buttonOffset = Offset(0, 4);
  static const numberFont = 'PixelifySans';
}
