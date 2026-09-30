import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppThemePreset {
  const AppThemePreset({
    required this.id,
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
    this.pageBackground = AppColors.pageBackground,
    this.primaryColor = AppColors.orbitPrimary,
    this.surfaceColor = AppColors.orbitSurface,
    this.selectedSurface = AppColors.orbitHalo,
    this.focusCardGradient = AppColors.focusCardGradient,
  });

  final String id;
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
  final Color pageBackground;
  final Color primaryColor;
  final Color surfaceColor;
  final Color selectedSurface;

  /// 홈 첫 카드 배경. 홈 화면 위젯 배경(`widget_medium_bg_*.xml`)과 같은 값이라
  /// 위젯에서 앱으로 들어와도 같은 카드가 이어진다.
  final LinearGradient focusCardGradient;

  static const softDay = AppThemePreset(
    id: 'soft_day',
    previewColors: [Color(0xFFF7F4EE), Color(0xFFF2EDF8), Color(0xFFF1ECE4)],
    pageGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF7F4EE), Color(0xFFFCFAF6), Color(0xFFF2EDF8)],
    ),
    shellGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFCF8), Color(0xFFF7F2FB), Color(0xFFF1ECE4)],
    ),
    primaryButtonGradient: LinearGradient(
      colors: [Color(0xFF5C3AF0), Color(0xFF8A63F6)],
    ),
    softAccentGradient: LinearGradient(
      colors: [Color(0xFF5C3AF0), Color(0xFF8A63F6)],
    ),
    highlightGradient: LinearGradient(
      colors: [Color(0xFFFF746C), Color(0xFFFFAD3D)],
    ),
    textPrimary: Color(0xFF241F31),
    textMuted: Color(0xFF6B6478),
    accentPink: Color(0xFFFF746C),
    accentLavender: Color(0xFFD9D1F2),
  );

  static const peachSunset = AppThemePreset(
    id: 'peach_sunset',
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

  static const poodleGarden = AppThemePreset(
    id: 'poodle_garden',
    previewColors: [
      Color(0xFF087E78),
      Color(0xFF53B987),
      Color(0xFFFFB740),
      Color(0xFFDDD1FA),
      Color(0xFFEEEAF7),
      Color(0xFF22294D),
    ],
    pageGradient: LinearGradient(
      colors: [Color(0xFFEEEAF7), Color(0xFFF8F6FC)],
    ),
    shellGradient: LinearGradient(
      colors: [Color(0xFFF8F6FC), Color(0xFFEEEAF7)],
    ),
    primaryButtonGradient: LinearGradient(
      colors: [Color(0xFF087E78), Color(0xFF20A999)],
    ),
    softAccentGradient: LinearGradient(
      colors: [Color(0xFFC9F1E5), Color(0xFFDDF7ED)],
    ),
    highlightGradient: LinearGradient(
      colors: [Color(0xFFFFD980), Color(0xFFFFB740)],
    ),
    textPrimary: Color(0xFF22294D),
    textMuted: Color(0xFF5E6482),
    accentPink: Color(0xFFFFB740),
    accentLavender: Color(0xFFDDD1FA),
    pageBackground: Color(0xFFEEEAF7),
    primaryColor: Color(0xFF087E78),
    surfaceColor: Color(0xFFFFFEFB),
    selectedSurface: Color(0xFFDDF7ED),
    focusCardGradient: LinearGradient(
      colors: [Color(0xFFF7F0FF), Color(0xFFD4F7E8)],
    ),
  );

  /// Stargazer Cat keeps app pages light; the home-screen widget gets the
  /// darker midnight palette separately.
  static const stargazer = AppThemePreset(
    id: 'stargazer',
    previewColors: [
      Color(0xFF0B3D4A),
      Color(0xFF3B5BD9),
      Color(0xFFF4C430),
      Color(0xFFFFF7E1),
    ],
    pageGradient: LinearGradient(
      colors: [Color(0xFFFFFBF1), Color(0xFFF5F8F3)],
    ),
    shellGradient: LinearGradient(
      colors: [Color(0xFFFFFCF5), Color(0xFFECF6F3)],
    ),
    primaryButtonGradient: LinearGradient(
      colors: [Color(0xFF0B5968), Color(0xFF176F7A)],
    ),
    softAccentGradient: LinearGradient(
      colors: [Color(0xFFDDF2EC), Color(0xFFE4EDFC)],
    ),
    highlightGradient: LinearGradient(
      colors: [Color(0xFFFFF3CB), Color(0xFFFFE7A6)],
    ),
    textPrimary: Color(0xFF18334A),
    textMuted: Color(0xFF536979),
    accentPink: Color(0xFFE6AD2A),
    accentLavender: Color(0xFFDCE8F8),
    pageBackground: Color(0xFFFFFBF1),
    primaryColor: Color(0xFF0B5968),
    surfaceColor: Color(0xFFFFFEFA),
    selectedSurface: Color(0xFFDDF2EC),
    focusCardGradient: LinearGradient(
      colors: [Color(0xFFFFF7E1), Color(0xFFE2F2EF)],
    ),
  );

  static const postmanRabbit = AppThemePreset(
    id: 'rabbit_postman',
    previewColors: [
      Color(0xFFFFE7D0),
      Color(0xFFFFB5A3),
      Color(0xFF9BCDB2),
      Color(0xFFFFF8E9),
    ],
    pageGradient: LinearGradient(
      colors: [Color(0xFFFFF8EC), Color(0xFFFFEDE4)],
    ),
    shellGradient: LinearGradient(
      colors: [Color(0xFFFFFCF4), Color(0xFFFFE9DD)],
    ),
    primaryButtonGradient: LinearGradient(
      colors: [Color(0xFFE97068), Color(0xFFFF9B82)],
    ),
    softAccentGradient: LinearGradient(
      colors: [Color(0xFFFFD9CD), Color(0xFFFFE7D0)],
    ),
    highlightGradient: LinearGradient(
      colors: [Color(0xFFFFD79A), Color(0xFFFFB5A3)],
    ),
    textPrimary: Color(0xFF493330),
    textMuted: Color(0xFF80645C),
    accentPink: Color(0xFFE97068),
    accentLavender: Color(0xFFC6E3CA),
    pageBackground: Color(0xFFFFF8EC),
    primaryColor: Color(0xFFDB665E),
    surfaceColor: Color(0xFFFFFEF8),
    selectedSurface: Color(0xFFFFE7D0),
    focusCardGradient: LinearGradient(
      colors: [Color(0xFFFFD7C7), Color(0xFFFFF3CF)],
    ),
  );

  static const explorerSquirrel = AppThemePreset(
    id: 'squirrel_explorer',
    previewColors: [
      Color(0xFFF6EFE0),
      Color(0xFFD8E5C9),
      Color(0xFF8DA16B),
      Color(0xFFB77D50),
    ],
    pageGradient: LinearGradient(
      colors: [Color(0xFFFCF7EB), Color(0xFFEAF1DD)],
    ),
    shellGradient: LinearGradient(
      colors: [Color(0xFFFFFBF1), Color(0xFFE6EDD9)],
    ),
    primaryButtonGradient: LinearGradient(
      colors: [Color(0xFF6F8B4F), Color(0xFF91A96B)],
    ),
    softAccentGradient: LinearGradient(
      colors: [Color(0xFFDDE8C7), Color(0xFFF5E5CA)],
    ),
    highlightGradient: LinearGradient(
      colors: [Color(0xFFF6DBA8), Color(0xFFEBC58C)],
    ),
    textPrimary: Color(0xFF3E3229),
    textMuted: Color(0xFF746C5A),
    accentPink: Color(0xFFC18A5A),
    accentLavender: Color(0xFFD7E3C0),
    pageBackground: Color(0xFFFCF7EB),
    primaryColor: Color(0xFF6F8B4F),
    surfaceColor: Color(0xFFFFFDF5),
    selectedSurface: Color(0xFFE2ECCA),
    focusCardGradient: LinearGradient(
      colors: [Color(0xFFF5E8CB), Color(0xFFDDEBCB)],
    ),
  );

  static const all = [
    softDay,
    peachSunset,
    mintLavender,
    poodleGarden,
    stargazer,
    postmanRabbit,
    explorerSquirrel
  ];

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
