import 'package:flutter/material.dart';

/// 루틴을 구분하는 공통 색상 토큰.
///
/// 배경과 본문은 차분하게 유지하고, 시간표 호·색상 스와치처럼 루틴의
/// 정체성을 나타내는 작은 면적에만 선명한 색을 사용한다.
abstract final class RoutinePalette {
  RoutinePalette._();

  static const int coralValue = 0xFFFF746C;
  static const int roseValue = 0xFFF65398;
  static const int amberValue = 0xFFFFAD3D;
  static const int lavenderValue = 0xFFA473F3;
  static const int orangeValue = 0xFFFF934B;
  static const int blueValue = 0xFF58B8E8;
  static const int greenValue = 0xFF60C68A;
  static const int violetValue = 0xFF7663E8;

  static const Color coral = Color(coralValue);
  static const Color rose = Color(roseValue);
  static const Color amber = Color(amberValue);
  static const Color lavender = Color(lavenderValue);
  static const Color orange = Color(orangeValue);
  static const Color blue = Color(blueValue);
  static const Color green = Color(greenValue);
  static const Color violet = Color(violetValue);

  static const List<Color> colors = [
    coral,
    rose,
    amber,
    lavender,
    orange,
    blue,
    green,
    violet,
  ];

  /// 이전 파스텔 팔레트로 저장된 루틴도 새 팔레트와 동일하게 보이게 한다.
  static int normalizeValue(int value) {
    final normalized = value & 0xFFFFFFFF;
    return switch (normalized) {
      0xFFFFE4E9 => coralValue,
      0xFFFFD4E0 => roseValue,
      0xFFFFE9D4 => amberValue,
      0xFFE8DDFA => lavenderValue,
      0xFFFFDDC5 => orangeValue,
      0xFFD4E4FF => blueValue,
      0xFFFFE8F0 => greenValue,
      0xFFD4C5F0 => violetValue,
      _ => normalized,
    };
  }
}
