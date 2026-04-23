import 'package:flutter/material.dart';
import 'app_colors.dart';

/// **타이포** 프리셋 — `Theme.of(context).textTheme`과 병행 가능
abstract final class AppTextStyles {
  static const TextStyle titleScreen = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.4,
  );

  static const TextStyle titleSection = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.35,
  );

  static const TextStyle hero = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.12,
    letterSpacing: -0.8,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    height: 1.35,
  );

  static const TextStyle captionTight = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static const TextStyle helper = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    height: 1.45,
  );

  /// 진행률 큰 숫자
  static const TextStyle statHero = TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1,
    letterSpacing: -1.0,
  );

  static const TextStyle statMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
