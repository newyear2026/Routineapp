import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_pixel_style.dart';

/// 56×48 터치 영역과 키보드 조작을 유지하는 사각 토글.
class AppPixelSwitch extends StatelessWidget {
  const AppPixelSwitch(
      {super.key,
      required this.value,
      required this.onChanged,
      this.label,
      this.decorative = false,
      this.accent = AppColors.orbitPrimary});
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  /// 누를 수 없지만 «켜짐»으로 보여야 하는 미리보기용 스위치.
  final bool decorative;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final live = enabled || decorative;
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
            width: 60,
            height: 48,
            child: Center(
                child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              width: 56,
              height: 32,
              padding: const EdgeInsets.all(3),
              decoration: ShapeDecoration(
                color: !live
                    ? AppColors.orbitSurfaceSoft
                    : value
                        ? accent
                        : AppColors.orbitSurface,
                // 깎는 양이 높이의 절반에 가까워지면 계단이 변을 다 먹어
                // 알약이 아니라 꼬리표처럼 보인다. 곧은 변을 남길 만큼만 깎는다.
                shape: AppPixelStyle.shape(
                  color: live ? AppPixelStyle.outline : AppColors.textMuted,
                  step: 3,
                  steps: 2,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  // 손잡이는 꺼짐일 때 트랙과 같은 흰색이라 사라져 보였다.
                  // 켜짐은 흰 손잡이, 꺼짐은 잉크 테두리 있는 회색 손잡이로 나눈다.
                  decoration: ShapeDecoration(
                    color: !live
                        ? AppColors.orbitSurface
                        : value
                            ? AppColors.orbitSurface
                            : AppColors.orbitSurfaceSoft,
                    shape: AppPixelStyle.shape(
                      color: live
                          ? AppPixelStyle.outline
                          : AppColors.textMuted,
                      step: 3,
                      steps: 2,
                    ),
                  ),
                ),
              ),
            )),
          ),
        ),
      ),
    );
  }
}
