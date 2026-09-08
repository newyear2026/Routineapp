import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_theme_preset.dart';
import 'app_text_styles.dart';

/// 앱 데이터나 콜백을 갖지 않는 공통 외형.
ThemeData buildRoutineTheme(
    {AppThemePreset preset = AppThemePreset.softDay, String? fontFamily}) {
  const shape = RoundedRectangleBorder(
      side: BorderSide(color: AppColors.textPrimary, width: 2));
  const border = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.textPrimary, width: 2));
  return ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: AppColors.pageBackground,
    extensions: [AppThemeTokens(preset: preset)],
    colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orbitPrimary,
        primary: AppColors.orbitPrimary,
        surface: AppColors.orbitSurface,
        error: AppColors.dangerText),
    splashFactory: NoSplash.splashFactory,
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.orbitSurface,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.orbitPrimary, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.dangerText, width: 2)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.dangerText, width: 2)),
      contentPadding: EdgeInsets.all(12),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.orbitSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: shape,
      titleTextStyle: AppTextStyles.titleSection,
      contentTextStyle: AppTextStyles.body,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.orbitSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: shape,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: shape,
      elevation: 0,
      focusElevation: 0,
      highlightElevation: 0,
    ),
    chipTheme: const ChipThemeData(
        shape: shape, side: BorderSide(color: AppColors.textPrimary, width: 2)),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
      shape: const RoundedRectangleBorder(),
      foregroundColor: AppColors.orbitPrimary,
      minimumSize: const Size(48, 48),
      textStyle: AppTextStyles.button,
    )),
    popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.orbitSurface, elevation: 0, shape: shape),
    snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(),
        actionTextColor: Colors.white),
  );
}
