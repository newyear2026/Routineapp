import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

class AppScreenShell extends StatelessWidget {
  const AppScreenShell({
    super.key,
    required this.child,
    this.background,
    this.padding = EdgeInsets.zero,
    this.maxWidth = AppLayout.maxContentWidth,
  });

  final Widget child;
  final Widget? background;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Stack(
          children: [
            if (background != null)
              Positioned.fill(
                child: IgnorePointer(child: background!),
              ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(padding: padding, child: child),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
