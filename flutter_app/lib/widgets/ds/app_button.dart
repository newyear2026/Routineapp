import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme_preset.dart';
import '../../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.expand = true,
    this.height = 56,
    this.isLoading = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool expand;
  final double height;
  final bool isLoading;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final radius = BorderRadius.circular(AppRadii.button);
    final child = Opacity(
      opacity: _enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Ink(
            width: expand ? double.infinity : null,
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            decoration: _decoration(theme),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: _foregroundColor, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                ] else if (isLoading) ...[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(_foregroundColor),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.button.copyWith(
                      color: _foregroundColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (expand) return child;
    return IntrinsicWidth(child: child);
  }

  Color get _foregroundColor {
    switch (variant) {
      case AppButtonVariant.primary:
        return Colors.white;
      case AppButtonVariant.secondary:
        return AppColors.textPrimary;
      case AppButtonVariant.ghost:
        return AppColors.textPrimary;
      case AppButtonVariant.destructive:
        return Colors.white;
    }
  }

  BoxDecoration _decoration(AppThemeTokens theme) {
    switch (variant) {
      case AppButtonVariant.primary:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.button),
          gradient: AppColors.orbitPrimaryGradient,
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: AppColors.orbitPrimary.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        );
      case AppButtonVariant.secondary:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.button),
          color: Colors.white.withValues(alpha: 0.74),
          border: Border.all(
            color: AppColors.orbitBorder.withValues(alpha: 0.9),
          ),
        );
      case AppButtonVariant.ghost:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.button),
          color: AppColors.orbitSurfaceSoft.withValues(alpha: 0.4),
        );
      case AppButtonVariant.destructive:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.button),
          gradient: const LinearGradient(
            colors: [Color(0xFFE78D76), Color(0xFFD76A5B)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD76A5B).withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        );
    }
  }
}
