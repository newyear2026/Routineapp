import 'package:flutter/material.dart';

/// Figma / Cute Emotional Routine — **색상·그라데이션** 단일 소스
///
/// Home · Routine Add · Progress 공통 사용.
abstract final class AppColors {
  // ── Text ────────────────────────────────────────
  static const Color textPrimary = Color(0xFF241F31);
  static const Color textMuted = Color(0xFF6B6478);
  static const Color textStrong = Color(0xFF241F31);

  // ── Accent & action ──────────────────────────────
  static const Color accentPink = Color(0xFFE5866B);
  static const Color accentLavender = Color(0xFFD9D1F2);
  static const Color orbitPrimary = Color(0xFF6C4CF1);
  static const Color orbitSecondary = Color(0xFFE5866B);
  static const Color orbitAccent = Color(0xFFF2C14E);
  static const Color orbitSurface = Color(0xFFFCFAF6);
  static const Color orbitSurfaceSoft = Color(0xFFF1ECE4);
  static const Color orbitBorder = Color(0xFFE4DCCF);
  static const Color orbitHalo = Color(0xFFD9D1F2);

  static const Color actionBlue = Color(0xFF5C72D8);
  static const Color actionOrange = Color(0xFFE4A165);
  static const Color actionRose = Color(0xFFD67888);
  static const Color success = Color(0xFF7FDD8F);
  static const Color warning = Color(0xFFD9A57B);

  // ── Border / divider ─────────────────────────────
  static const Color border = Color(0xFFE4DCCF);

  // ── Surface (알파는 withValues로 조합) ────────────
  static const Color surface = Color(0xFFFFFFFF);

  // ── Page & shell ─────────────────────────────────
  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF7F4EE),
      Color(0xFFFCFAF6),
      Color(0xFFF2EDF8),
    ],
  );

  static const LinearGradient shellGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFCF8),
      Color(0xFFF7F2FB),
      Color(0xFFF1ECE4),
    ],
  );

  /// Primary CTA (저장·완료 등)
  static const LinearGradient primaryButtonGradient = LinearGradient(
    colors: [Color(0xFF5E43E8), Color(0xFF8E6AF5)],
  );

  static const LinearGradient softAccentGradient = LinearGradient(
    colors: [Color(0xFF5E43E8), Color(0xFF8E6AF5)],
  );

  static const LinearGradient highlightGradient = LinearGradient(
    colors: [Color(0xFFE5866B), Color(0xFFF2C14E)],
  );

  static const LinearGradient orbitBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF7F4EE),
      Color(0xFFFCFAF6),
      Color(0xFFF2EDF8),
    ],
  );

  static const LinearGradient orbitCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFCF8),
      Color(0xFFF9F5FF),
    ],
  );

  static const LinearGradient orbitPrimaryGradient = LinearGradient(
    colors: [Color(0xFF5E43E8), Color(0xFF8E6AF5)],
  );

  static const LinearGradient orbitWarmGradient = LinearGradient(
    colors: [Color(0xFFE5866B), Color(0xFFF2C14E)],
  );

  /// Progress 링 등 강조
  static const Color progressRing = accentPink;

  // ── Shadow ───────────────────────────────────────
  static Color shellShadow(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.12);
}
