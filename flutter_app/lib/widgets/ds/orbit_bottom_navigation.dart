import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme_preset.dart';
import '../../theme/app_text_styles.dart';
import 'pixel_icon.dart';

/// Figma의 4분할 하단 탭. 아이콘과 라벨은 하나의 중심선을 공유한다.
class OrbitBottomNavigation extends StatelessWidget {
  const OrbitBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onHome,
    required this.onProgress,
    required this.onRoutines,
    required this.onSettings,
  });

  final int currentIndex;
  final VoidCallback onHome;
  final VoidCallback onProgress;
  final VoidCallback onRoutines;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <_OrbitNavItemData>[
      _OrbitNavItemData(Icons.home_outlined, l10n.navHome),
      _OrbitNavItemData(Icons.pie_chart_outline_rounded, l10n.navProgress),
      _OrbitNavItemData(Icons.format_list_bulleted_rounded, l10n.navRoutines),
      _OrbitNavItemData(Icons.settings_outlined, l10n.navSettings),
    ];
    final callbacks = [onHome, onProgress, onRoutines, onSettings];
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;
    final selectedSurface = context.appTheme.preset.selectedSurface;
    const glyphs = [
      PixelGlyph.navHome,
      PixelGlyph.navProgress,
      PixelGlyph.navRoutines,
      PixelGlyph.navSettings,
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        border: const Border(
            top: BorderSide(color: AppColors.textPrimary, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          // 라틴 문자는 한글보다 행 높이가 크고, 시스템 글꼴을 키우면 더
          // 늘어난다. 높이를 못 박으면 라벨 아래가 잘린다.
          constraints: const BoxConstraints(minHeight: 86),
          child: Row(
            children: List.generate(items.length, (index) {
              final selected = index == currentIndex;
              return Expanded(
                child: Semantics(
                  selected: selected,
                  button: true,
                  label: l10n.navTabSemantic(items[index].label),
                  child: InkWell(
                    onTap: callbacks[index],
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? selectedSurface.withValues(alpha: 0.55)
                            : Colors.transparent,
                        border: Border(
                            top: BorderSide(
                                color: selected ? primary : Colors.transparent,
                                width: 3)),
                      ),
                      padding: const EdgeInsets.only(top: 14, bottom: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PixelIcon(glyphs[index],
                              size: 24,
                              color: selected ? primary : AppColors.textMuted),
                          const SizedBox(height: 5),
                          Text(
                            items[index].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: selected ? primary : AppColors.textMuted,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _OrbitNavItemData {
  const _OrbitNavItemData(this.icon, this.label);

  final IconData icon;
  final String label;
}
