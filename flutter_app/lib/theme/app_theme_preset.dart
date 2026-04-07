import 'package:flutter/material.dart';

class AppThemePreset {
  const AppThemePreset({
    required this.id,
    required this.label,
    required this.previewColors,
    required this.pageGradient,
    required this.shellGradient,
    required this.primaryButtonGradient,
    required this.softAccentGradient,
    required this.highlightGradient,
    required this.textPrimary,
    required this.textMuted,
    required this.accentPink,
    required this.accentLavender,
  });

  final String id;
  final String label;
  final List<Color> previewColors;
  final LinearGradient pageGradient;
  final LinearGradient shellGradient;
  final LinearGradient primaryButtonGradient;
  final LinearGradient softAccentGradient;
  final LinearGradient highlightGradient;
  final Color textPrimary;
  final Color textMuted;
  final Color accentPink;
  final Color accentLavender;

  static const softDay = AppThemePreset(
    id: 'soft_day',
    label: '소프트 데이',
    previewColors: [Color(0xFFFFF5F5), Color(0xFFFFF9E6), Color(0xFFF0F4FF)],
    pageGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF5F5), Color(0xFFFFF9E6), Color(0xFFF0F4FF)],
    ),
    shellGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF8F3), Color(0xFFFFF5F8), Color(0xFFF5F0FF)],
    ),
    primaryButtonGradient: LinearGradient(
      colors: [Color(0xFFD4E4FF), Color(0xFFC5D5F0)],
    ),
    softAccentGradient: LinearGradient(
      colors: [Color(0xFFD4C5F0), Color(0xFFC4B5E6)],
    ),
    highlightGradient: LinearGradient(
      colors: [Color(0xFFFFE9D4), Color(0xFFFFDDC5)],
    ),
    textPrimary: Color(0xFF473A57),
    textMuted: Color(0xFF6F617F),
    accentPink: Color(0xFFFFB8C6),
    accentLavender: Color(0xFFD4C5F0),
  );

  static const peachSunset = AppThemePreset(
    id: 'peach_sunset',
    label: '피치 선셋',
    previewColors: [Color(0xFFFFF0E8), Color(0xFFFFE1D6), Color(0xFFFFF3E6)],
    pageGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF0E8), Color(0xFFFFE1D6), Color(0xFFFFF3E6)],
    ),
    shellGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF7F0), Color(0xFFFFEFE6), Color(0xFFFFE6E1)],
    ),
    primaryButtonGradient: LinearGradient(
      colors: [Color(0xFFFFD6C2), Color(0xFFFFBFA8)],
    ),
    softAccentGradient: LinearGradient(
      colors: [Color(0xFFFFC4B8), Color(0xFFF3A991)],
    ),
    highlightGradient: LinearGradient(
      colors: [Color(0xFFFFE8C9), Color(0xFFFFD7B0)],
    ),
    textPrimary: Color(0xFF5A403E),
    textMuted: Color(0xFF836863),
    accentPink: Color(0xFFFFB39F),
    accentLavender: Color(0xFFFFC9B3),
  );

  static const mintLavender = AppThemePreset(
    id: 'mint_lavender',
    label: '민트 라벤더',
    previewColors: [Color(0xFFF1FFF8), Color(0xFFF1F7FF), Color(0xFFF7F0FF)],
    pageGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF1FFF8), Color(0xFFF1F7FF), Color(0xFFF7F0FF)],
    ),
    shellGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF8FFFC), Color(0xFFF5FBFF), Color(0xFFF8F2FF)],
    ),
    primaryButtonGradient: LinearGradient(
      colors: [Color(0xFFCDEFE1), Color(0xFFB8DCEC)],
    ),
    softAccentGradient: LinearGradient(
      colors: [Color(0xFFBFE7DA), Color(0xFFBFD1F0)],
    ),
    highlightGradient: LinearGradient(
      colors: [Color(0xFFE4F7F0), Color(0xFFDDEAF8)],
    ),
    textPrimary: Color(0xFF3E4F56),
    textMuted: Color(0xFF667A84),
    accentPink: Color(0xFF9FD9C8),
    accentLavender: Color(0xFFBFD1F0),
  );

  static const all = [softDay, peachSunset, mintLavender];

  static AppThemePreset byId(String? id) {
    return all.firstWhere(
      (preset) => preset.id == id,
      orElse: () => softDay,
    );
  }
}

@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.preset,
  });

  final AppThemePreset preset;

  LinearGradient get pageGradient => preset.pageGradient;
  LinearGradient get shellGradient => preset.shellGradient;
  LinearGradient get primaryButtonGradient => preset.primaryButtonGradient;
  LinearGradient get softAccentGradient => preset.softAccentGradient;
  LinearGradient get highlightGradient => preset.highlightGradient;
  Color get textPrimary => preset.textPrimary;
  Color get textMuted => preset.textMuted;
  Color get accentPink => preset.accentPink;
  Color get accentLavender => preset.accentLavender;

  @override
  ThemeExtension<AppThemeTokens> copyWith({
    AppThemePreset? preset,
  }) {
    return AppThemeTokens(
      preset: preset ?? this.preset,
    );
  }

  @override
  ThemeExtension<AppThemeTokens> lerp(
    covariant ThemeExtension<AppThemeTokens>? other,
    double t,
  ) {
    if (other is! AppThemeTokens) return this;
    return t < 0.5 ? this : other;
  }
}

extension AppThemeContext on BuildContext {
  AppThemeTokens get appTheme =>
      Theme.of(this).extension<AppThemeTokens>() ??
      const AppThemeTokens(preset: AppThemePreset.softDay);
}
