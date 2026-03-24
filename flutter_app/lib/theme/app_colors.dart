import 'package:flutter/material.dart';

/// Figma / Cute Emotional Routine — **색상·그라데이션** 단일 소스
///
/// Home · Routine Add · Progress 공통 사용.
abstract final class AppColors {
  // ── Text ─────────────────────────────────────────
  static const Color textPrimary = Color(0xFF8B7B9E);
  static const Color textMuted = Color(0xFFB8A4C9);

  // ── Accent & action ──────────────────────────────
  static const Color accentPink = Color(0xFFFFB8C6);
  static const Color accentLavender = Color(0xFFD4C5F0);

  static const Color actionBlue = Color(0xFF6B8BC9);
  static const Color actionOrange = Color(0xFFD9A57B);
  static const Color actionRose = Color(0xFFD99BB0);

  // ── Border / divider ─────────────────────────────
  static const Color border = Color(0xFFE8DDFA);

  // ── Surface (알파는 withValues로 조합) ────────────
  static const Color surface = Color(0xFFFFFFFF);

  // ── Page & shell ─────────────────────────────────
  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF5F5),
      Color(0xFFFFF9E6),
      Color(0xFFF0F4FF),
    ],
  );

  static const LinearGradient shellGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFF8F3),
      Color(0xFFFFF5F8),
      Color(0xFFF5F0FF),
    ],
  );

  /// Primary CTA (저장·완료 등)
  static const LinearGradient primaryButtonGradient = LinearGradient(
    colors: [Color(0xFFD4E4FF), Color(0xFFC5D5F0)],
  );

  /// Progress 링 등 강조
  static const Color progressRing = accentPink;

  // ── Shadow ───────────────────────────────────────
  static Color shellShadow(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.12);
}
