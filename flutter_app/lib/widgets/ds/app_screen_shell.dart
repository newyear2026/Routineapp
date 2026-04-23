import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme_preset.dart';
import '../home/home_decorative_background.dart';

class AppScreenShell extends StatelessWidget {
  const AppScreenShell({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.showDecor = true,
    this.maxWidth = AppLayout.maxContentWidth,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showDecor;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(gradient: theme.pageGradient),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.shellMargin),
              padding: padding,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.shell),
                gradient: theme.shellGradient,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orbitPrimary.withValues(alpha: 0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  if (showDecor)
                    const Positioned.fill(child: HomeDecorativeBackground()),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
