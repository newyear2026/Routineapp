import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_theme_preset.dart';
import 'app_text_styles.dart';
import 'app_pixel_style.dart';

/// 앱 데이터나 콜백을 갖지 않는 공통 외형.
ThemeData buildRoutineTheme(
    {AppThemePreset preset = AppThemePreset.softDay, String? fontFamily}) {
  final shape = AppPixelStyle.shape();
  // 입력창은 Flutter가 InputBorder 계열만 받아 도형을 갈아 끼울 수 없다.
  // 테두리 굵기와 색을 맞춰 두고, 모서리는 직각으로 남긴다.
  const border = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(
          color: AppColors.textPrimary, width: AppPixelStyle.borderWidth));
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
      // 상태는 색으로만 말한다. 굵기까지 바뀌면 포커스가 들고 날 때마다
      // 테두리가 1.5 ↔ 2 로 튄다.
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
              color: AppColors.orbitPrimary,
              width: AppPixelStyle.borderWidth)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
              color: AppColors.dangerText, width: AppPixelStyle.borderWidth)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
              color: AppColors.dangerText, width: AppPixelStyle.borderWidth)),
      contentPadding: EdgeInsets.all(12),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.orbitSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: shape,
      titleTextStyle: AppTextStyles.titleSection,
      contentTextStyle: AppTextStyles.body,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.orbitSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: shape,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: shape,
      elevation: 0,
      focusElevation: 0,
      highlightElevation: 0,
    ),
    chipTheme: ChipThemeData(
        shape: AppPixelStyle.shape(),
        side: const BorderSide(
            color: AppColors.textPrimary, width: AppPixelStyle.borderWidth)),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
      shape: const RoundedRectangleBorder(),
      foregroundColor: AppColors.orbitPrimary,
      minimumSize: const Size(48, 48),
      textStyle: AppTextStyles.button,
    )),
    popupMenuTheme: PopupMenuThemeData(
        color: AppColors.orbitSurface, elevation: 0, shape: shape),
    snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: AppPixelStyle.shape(color: Colors.transparent, width: 0),
        actionTextColor: Colors.white),
  );
}
