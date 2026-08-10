import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class AppScreenShell extends StatelessWidget {
  const AppScreenShell({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.maxWidth = AppLayout.maxContentWidth,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.pageBackground,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
