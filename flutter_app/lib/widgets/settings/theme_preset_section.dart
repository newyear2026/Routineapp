import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_preset.dart';
import '../ds/ds.dart';

/// 테마 프리셋 — **아직 화면에 연결되어 있지 않다.**
///
/// [AppThemeTokens]는 `main.dart`에서 테마에 주입되지만, 실제로 읽는 화면이
/// 없다(모든 화면이 [AppColors] 상수를 직접 참조한다). 고를 수 있는 것처럼
/// 두면 눌러도 아무 픽셀이 바뀌지 않는 토글이 된다 — UI_STANDARDS 4의
/// '준비 중 기능은 실제 동작하는 토글처럼 보이면 안 된다'에 어긋난다.
///
/// 연결할 때 함께 해야 할 일: 프리셋마다 버튼 전경색 토큰을 추가한다.
/// 지금 값 그대로 이으면 피치/민트의 버튼 그라데이션(`#FFD6C2` 계열) 위
/// 흰 글자가 1.5:1로 읽히지 않는다.
class ThemePresetSection extends StatelessWidget {
  const ThemePresetSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('테마 프리셋',
                  style: AppTextStyles.titleSection.copyWith(fontSize: 15)),
              const SizedBox(width: 8),
              const AppStatusBadge(
                label: '준비 중',
                tone: AppStatusBadgeTone.readySoon,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('다음 업데이트에서 테마를 고를 수 있어요.',
              style: AppTextStyles.caption),
          const SizedBox(height: 14),
          for (final preset in AppThemePreset.all)
            _ThemePresetOption(preset: preset),
        ],
      ),
    );
  }
}

class _ThemePresetOption extends StatelessWidget {
  const _ThemePresetOption({required this.preset});

  final AppThemePreset preset;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Opacity(
          opacity: 0.45,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              ...preset.previewColors.map((color) => Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(right: 6),
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  )),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(preset.label,
                      style: AppTextStyles.bodyStrong.copyWith(fontSize: 15))),
            ]),
          ),
        ),
      );
}
