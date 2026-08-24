import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

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

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.orbitSurface,
        border: Border(top: BorderSide(color: AppColors.orbitBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 86,
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
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            items[index].icon,
                            size: 24,
                            color: selected
                                ? AppColors.orbitPrimary
                                : AppColors.textMuted,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            items[index].label,
                            style: AppTextStyles.caption.copyWith(
                              color: selected
                                  ? AppColors.orbitPrimary
                                  : AppColors.textMuted,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
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
