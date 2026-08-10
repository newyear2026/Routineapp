import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 홈 화면 Medium 위젯의 **색 단일 소스**.
///
/// 위젯은 Flutter(앱 내 미리보기) · SwiftUI(iOS) · XML+Canvas(Android)
/// 세 벌로 그려진다. 세 곳이 각자 hex를 적어두면 앱 팔레트를 바꿔도 위젯만
/// 옛 색으로 남는다 — 실제로 그렇게 어긋나 있었다.
///
/// 그래서 **이 파일이 기준**이고, 네이티브는 아래 값을 그대로 미러링한다.
/// 값을 바꾸면 세 곳을 함께 고쳐야 한다:
///
/// - iOS: `ios/RoutineWidgetExtension/RoutineWidgetExtension.swift`의 `WidgetTokens`
/// - Android: `android/app/src/main/res/values/widget_colors.xml`
///   그리고 `RoutineWidgetRingBitmap.kt`의 `Tokens`
///
/// 매핑 근거: 위젯은 홈 화면의 축소판이므로, 앱 홈에서 원형 시간표가 놓이는
/// 배경([AppColors.pageBackground])과 같은 서피스를 쓴다.
abstract final class WidgetTheme {
  /// #EEE8DE — 위젯 바탕 (앱 홈 배경과 동일)
  static const Color background = AppColors.pageBackground;

  /// #FFFFFF — 링 내부 원반, '다음' 칩 등 올라오는 면
  static const Color surface = AppColors.orbitSurface;

  /// #DCD3C4 — 칩 테두리
  static const Color border = AppColors.orbitBorder;

  /// #241F31 — 루틴 이름·시각. 배경 위 13.6:1
  static const Color textPrimary = AppColors.textPrimary;

  /// #6B6478 — 보조 문구. 배경 위 4.63:1 (AA 통과)
  static const Color textMuted = AppColors.textMuted;

  /// #6744F4 — 상태 배지 채움·현재 시각 포인터. 흰 글자와 5.66:1
  static const Color accent = AppColors.orbitPrimary;

  /// #D9D1F2 — 24시간 트랙
  static const Color ringTrack = AppColors.orbitHalo;

  /// 배지 위 글자
  static const Color onAccent = Colors.white;

  // ── 글자 크기 ────────────────────────────────────
  // UI_STANDARDS 6: 본문 정보 텍스트는 13 미만으로 내려가지 않는다.
  // 배지·시각 라벨만 12(캡션)를 쓴다.
  static const double titleSize = 20;
  static const double bodySize = 13;
  static const double captionSize = 12;
}
