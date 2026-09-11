import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_pixel_style.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_preset.dart';
import '../ds/ds.dart';

/// 테마 프리셋 — **아직 화면에 연결되어 있지 않다.**
///
/// 시안의 가로 스와치 3칸만 보여 주고, 눌러도 테마가 바뀌지 않는다.
class ThemePresetSection extends StatelessWidget {
  const ThemePresetSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsThemeSection, style: AppTextStyles.titleSection),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < AppThemePreset.all.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _ThemeSwatchCard(
                  preset: AppThemePreset.all[i],
                  selected: i == 0,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ThemeSwatchCard extends StatelessWidget {
  const _ThemeSwatchCard({required this.preset, required this.selected});

  final AppThemePreset preset;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      label: _presetLabel(AppLocalizations.of(context), preset),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: ShapeDecoration(
          color: AppColors.orbitSurface,
          shape: AppPixelStyle.shape(
            color: selected ? AppColors.orbitPrimary : AppColors.orbitBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (selected)
              const Align(
                alignment: Alignment.centerLeft,
                child: AppIcon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.orbitPrimary,
                ),
              )
            else
              const SizedBox(height: 16),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final color in preset.previewColors.take(3))
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.orbitBorder),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _presetLabel(AppLocalizations l10n, AppThemePreset preset) {
  switch (preset.id) {
    case 'peach_sunset':
      return l10n.themePeachSunset;
    case 'mint_lavender':
      return l10n.themeMintLavender;
    default:
      return l10n.themeSoftDay;
  }
}
