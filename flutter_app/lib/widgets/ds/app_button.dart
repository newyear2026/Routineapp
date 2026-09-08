import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_pixel_style.dart';
import '../../theme/app_text_styles.dart';
import 'pixel_icon.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive }

class AppButton extends StatefulWidget {
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

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;
  bool _focused = false;
  bool get _enabled => widget.onPressed != null && !widget.isLoading;
  bool get _ghost => widget.variant == AppButtonVariant.ghost;

  @override
  Widget build(BuildContext context) {
    final pressed = _pressed && _enabled;
    final foreground = switch (widget.variant) {
      AppButtonVariant.primary || AppButtonVariant.destructive => Colors.white,
      AppButtonVariant.secondary => AppColors.textPrimary,
      AppButtonVariant.ghost => AppColors.textMuted,
    };
    final fill = switch (widget.variant) {
      AppButtonVariant.primary => AppColors.orbitPrimary,
      AppButtonVariant.secondary => AppColors.orbitSurface,
      AppButtonVariant.ghost => Colors.transparent,
      AppButtonVariant.destructive => AppColors.dangerText,
    };

    final child = Padding(
      // 누를 때 다음 요소와 겹치지 않도록 그림자 공간을 유지한다.
      padding:
          EdgeInsets.only(bottom: _ghost ? 0 : AppPixelStyle.buttonOffset.dy),
      child: Opacity(
        opacity: _enabled || widget.isLoading ? 1 : 0.5,
        child: Transform.translate(
          offset: pressed && !_ghost ? AppPixelStyle.buttonOffset : Offset.zero,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _enabled ? widget.onPressed : null,
              borderRadius: AppPixelStyle.radius,
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              // InkWell을 유지해 키보드·스크린리더 활성화를 보존한다.
              onHighlightChanged: (value) => setState(() => _pressed = value),
              onFocusChange: (value) => setState(() => _focused = value),
              child: Ink(
                width: widget.expand ? double.infinity : null,
                height: widget.height,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: fill,
                  border: _ghost && !_focused
                      ? null
                      : Border.all(
                          color: _focused
                              ? AppColors.orbitSecondary
                              : AppPixelStyle.outline,
                          width: AppPixelStyle.borderWidth,
                        ),
                  boxShadow: _ghost || pressed || !_enabled
                      ? null
                      : const [
                          BoxShadow(
                            color: AppPixelStyle.shadow,
                            offset: AppPixelStyle.buttonOffset,
                          )
                        ],
                ),
                child: Row(
                  mainAxisSize:
                      widget.expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isLoading) ...[
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation(foreground),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ] else if (widget.icon != null) ...[
                      AppIcon(widget.icon!, color: foreground, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.button.copyWith(color: foreground),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.expand) return child;
    return IntrinsicWidth(child: child);
  }
}
