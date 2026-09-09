import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'pixel_border.dart';

/// Sobra의 단색 서피스·직각 테두리·단단한 그림자를 루틴 앱 색상에 맞춘다.
/// 데이터나 화면 동작에는 관여하지 않는다.
abstract final class AppPixelStyle {
  static const borderWidth = 1.5;
  static const radius = BorderRadius.zero;

  /// 모서리 계단 — 한 칸 크기와 칸 수.
  static const cornerStep = 3.0;
  static const cornerSteps = 3;

  /// 작은 컨트롤(칩·배지·토글 손잡이)은 같은 칸 수로 깎으면 모서리가 다 먹는다.
  static const cornerStepSmall = 3.0;
  static const outline = AppColors.textPrimary;
  static const shadow = Color(0x33948362);
  static const cardOffset = Offset(3, 3);
  static const heroOffset = Offset(4, 4);
  static const buttonOffset = Offset(0, 4);
  static const numberFont = 'PixelifySans';

  /// 공통 외곽선 도형. [color]/[width]를 주지 않으면 기본 잉크 2px.
  static PixelBorder shape({
    Color? color,
    double? width,
    double step = cornerStep,
    int steps = cornerSteps,
  }) =>
      PixelBorder(
        side: BorderSide(color: color ?? outline, width: width ?? borderWidth),
        step: step,
        steps: steps,
      );

  /// 테두리 없이 면만 깎을 때(내부 채움·클리핑용).
  static const PixelBorder plainShape =
      PixelBorder(step: cornerStep, steps: cornerSteps);
}
