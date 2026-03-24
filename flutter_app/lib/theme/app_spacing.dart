import 'package:flutter/material.dart';

/// **간격·라운드·레이아웃** 기준 (8pt 그리드)
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 28;
  static const double huge = 32;

  /// 화면 좌우 패딩 (Home / Add / Progress 공통)
  static const double screenHorizontal = 24;

  /// 쉘 바깥 마진
  static const double shellMargin = 16;

  /// 섹션 사이 세로 간격
  static const double sectionGap = 16;

  /// 카드 내부 패딩 기본값
  static const double cardPadding = 18;

  static const EdgeInsets screenPaddingH = EdgeInsets.symmetric(horizontal: screenHorizontal);

  static const EdgeInsets scrollContent = EdgeInsets.fromLTRB(screenHorizontal, 8, screenHorizontal, xxxl);
}

/// **코너 반경**
abstract final class AppRadii {
  static const double chip = 14;
  static const double input = 18;
  static const double card = 22;
  static const double cardLarge = 28;
  static const double button = 28;
  static const double shell = 40;

  static BorderRadius borderRadius(double r) => BorderRadius.circular(r);
}

/// **최대 콘텐츠 폭** (모바일 프레임)
abstract final class AppLayout {
  static const double maxContentWidth = 390;
}
