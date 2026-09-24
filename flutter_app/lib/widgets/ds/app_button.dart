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
      AppButtonVariant.primary => Theme.of(context).colorScheme.primary,
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
              child: CustomPaint(
                // 베벨은 «밝은 위 / 어두운 아래»로 면이 솟은 듯 보이게 한다.
                // 흰 면에서는 위쪽 하이라이트가 묻히고 아래쪽 어두운 획만
                // 남아, 솟아 보이는 대신 회색 테두리가 하나 더 생긴다.
                // 그래서 글자가 흰색인 어두운 면에만 건다.
                foregroundPainter: foreground == Colors.white && !_ghost
                    ? _ButtonBevel(pressed: pressed)
                    : null,
                child: Ink(
                  width: widget.expand ? double.infinity : null,
                  height: widget.height,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  decoration: ShapeDecoration(
                    color: fill,
                    shape: _ghost && !_focused
                        ? AppPixelStyle.plainShape
                        : AppPixelStyle.shape(
                            color: _focused
                                ? AppColors.orbitSecondary
                                : AppPixelStyle.outline,
                          ),
                    shadows: _ghost || pressed || !_enabled
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
                          style:
                              AppTextStyles.button.copyWith(color: foreground),
                        ),
                      ),
                    ],
                  ),
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

/// 면 전체를 밝히지 않고 가장자리만 강조해 버튼 글자 대비를 유지한다.
class _ButtonBevel extends CustomPainter {
  const _ButtonBevel({required this.pressed});
  final bool pressed;

  /// 테두리 안쪽으로 이만큼 들어간 자리에 획을 둔다.
  static const _inset = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Offset.zero & size;
    final rect = outer.deflate(_inset);
    if (rect.isEmpty) return;
    final shader = LinearGradient(
      begin: pressed ? Alignment.bottomCenter : Alignment.topCenter,
      end: pressed ? Alignment.topCenter : Alignment.bottomCenter,
      colors: const [Color(0x99FFFFFF), Color(0x00221C42), Color(0x33221C42)],
      stops: const [0, 0.5, 1],
    ).createShader(rect);
    canvas.drawPath(
      // 사각형만 줄인 경로를 쓰면 모서리 계단이 테두리와 평행하지 않아
      // 네 귀퉁이만 간격이 벌어진다. 도형에게 평행한 경로를 직접 받는다.
      AppPixelStyle.plainShape.insetPath(outer, _inset),
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(_ButtonBevel oldDelegate) =>
      oldDelegate.pressed != pressed;
}
