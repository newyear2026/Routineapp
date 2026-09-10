import 'package:flutter/material.dart';

/// Figma / Cute Emotional Routine — **색상·그라데이션** 단일 소스
///
/// Home · Routine Add · Progress 공통 사용.
abstract final class AppColors {
  // Decorative surfaces never substitute for semantic status text colors.
  static const decorationCloud = Color(0xFFD3C9F6);
  static const decorationSpark = Color(0xFFA98BEC);
  static const decorationCream = Color(0xFFFFFCF4);
  static const decorationOutline = Color(0xFFC7B79C);
  static const dialSurface = Color(0xFFF3EDF9);
  static const errorSurface = Color(0xFFFFF0EC);
  static const readySoonText = Color(0xFF9C4A2F);
  // ── Text ────────────────────────────────────────
  static const Color textPrimary = Color(0xFF221C42);
  static const Color textMuted = Color(0xFF6A6489);
  static const Color textStrong = Color(0xFF221C42);

  // ── Accent & action ──────────────────────────────
  static const Color orbitPrimary = Color(0xFF6744F4);
  static const Color orbitSecondary = Color(0xFFFF746C);
  static const Color orbitAccent = Color(0xFFFFAD3D);

  /// 카드·패널 서피스. 페이지 배경([pageBackground])과 확실히 분리되도록 순백을 쓴다.
  static const Color orbitSurface = Color(0xFFFFFFFF);

  /// 보조 pill·트랙 등 한 단계 눌린 서피스
  static const Color orbitSurfaceSoft = Color(0xFFF0E9D9);
  static const Color orbitBorder = Color(0xFFE5DCC8);
  static const Color orbitHalo = Color(0xFFE4DCFB);

  /// 앱 전체 페이지 배경.
  ///
  /// 시안의 크림 쪽으로 옮기되 서피스(순백)와의 명도차 ΔL* ≥ 5 는 지킨다.
  /// 처음 잡았던 #F9F3E3 은 ΔL* 4.1 이라 카드가 그림자로만 구분됐다.
  /// 이 값은 ΔL* 5.9 로, design_tokens_contrast_test 가 이 선을 지킨다.
  static const Color pageBackground = Color(0xFFF5EEDA);

  // ── Status: 채움용(fill)과 글자용(text)을 분리한다 ─
  // fill 계열은 배지 배경·점 등 장식에만 쓰고,
  // 글자·아이콘에는 반드시 *Text 토큰을 써서 대비 4.5:1 이상을 지킨다.
  static const Color success = Color(0xFF7FDD8F);
  static const Color warning = Color(0xFFD9A57B);

  /// 흰 서피스 위 5.0:1 — '완료' 라벨
  static const Color successText = Color(0xFF2E7D4F);

  /// 흰 서피스 위 5.4:1 — '예정' 라벨
  static const Color scheduledText = Color(0xFF8A6320);

  /// 흰 서피스 위 5.3:1 — '진행 중' 라벨 (orbitPrimary와 동일 색)
  static const Color activeText = orbitPrimary;

  /// 흰 서피스 위 4.8:1 — 삭제·되돌리기 어려운 행동
  static const Color dangerText = Color(0xFFB03A2E);

  // ── Border / divider ─────────────────────────────
  static const Color border = Color(0xFFE5DCC8);

  // ── Page & shell ─────────────────────────────────
  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEEE8DE),
      Color(0xFFF2ECE3),
      Color(0xFFEBE5F0),
    ],
  );

  static const LinearGradient orbitPrimaryGradient = LinearGradient(
    colors: [Color(0xFF5C3AF0), Color(0xFF8A63F6)],
  );

  // ── Shadow ───────────────────────────────────────
  static Color shellShadow(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.12);
}
