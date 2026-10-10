import 'package:flutter/material.dart';

import '../../domain/models/routine_icon_id.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_pixel_style.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_preset.dart';
import '../../widgets/ds/pixel_icon.dart';
import '../../widgets/ds/routine_mark.dart';

/// 일반 루틴 초안을 유지한 채 별도 수면 설정으로 이동한다.
class SleepRoutineEntryCard extends StatelessWidget {
  const SleepRoutineEntryCard({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTheme;
    final shape = AppPixelStyle.shape(color: tokens.textPrimary);
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Material(
        color: Color.alphaBlend(
          tokens.accentLavender.withValues(alpha: .4),
          Theme.of(context).colorScheme.surface,
        ),
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                RoutineMark(
                  icon: RoutineIconId.moon,
                  color: tokens.accentLavender,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.sleepCreateTitle,
                        style: AppTextStyles.titleSection.copyWith(
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.sleepCreateDescription,
                        style: AppTextStyles.caption.copyWith(
                          color: tokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PixelIcon(
                  PixelGlyph.chevronRight,
                  size: 20,
                  color: tokens.textPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
