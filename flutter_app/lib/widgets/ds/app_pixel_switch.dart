import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_pixel_style.dart';
import 'pixel_icon.dart';

/// 56×48 터치 영역과 키보드 조작을 유지하는 사각 토글.
class AppPixelSwitch extends StatelessWidget {
  const AppPixelSwitch(
      {super.key,
      required this.value,
      required this.onChanged,
      this.label,
      this.accent = AppColors.orbitPrimary});
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    void toggle() => onChanged?.call(!value);
    return Semantics(
      label: label,
      toggled: value,
      enabled: enabled,
      onTap: enabled ? toggle : null,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? toggle : null,
          borderRadius: BorderRadius.zero,
          splashFactory: NoSplash.splashFactory,
          child: SizedBox(
            width: 56,
            height: 48,
            child: Center(
                child: Container(
              width: 52,
              height: 30,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: !enabled
                    ? AppColors.orbitSurfaceSoft
                    : value
                        ? accent
                        : AppColors.orbitSurface,
                border: Border.all(
                    color:
                        enabled ? AppPixelStyle.outline : AppColors.textMuted,
                    width: 2),
              ),
              child: Align(
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                      color: AppColors.orbitSurface,
                      border: Border.all(color: AppPixelStyle.outline)),
                  // 손잡이가 20×20이라 AppIcon의 광학 보정을 받으면 넘친다.
                  child: value
                      ? PixelIcon(PixelGlyph.check,
                          size: 18,
                          color: enabled ? accent : AppColors.textMuted)
                      : null,
                ),
              ),
            )),
          ),
        ),
      ),
    );
  }
}
