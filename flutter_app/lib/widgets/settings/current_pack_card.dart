import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../ds/ds.dart';
import '../store/character_pack_preview.dart';
import '../store/character_pack_scope.dart';
import '../store/character_pack_text.dart';

/// 지금 쓰는 팩을 보여 주고 팩 목록으로 보낸다.
///
/// 설정에서 외형을 다루는 자리는 여기 하나다. 캐릭터와 테마를 따로 고르는
/// 자리를 두면, 파는 단위(팩)와 고르는 단위가 어긋난다.
class CurrentPackCard extends StatelessWidget {
  const CurrentPackCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pack = CharacterPackScope.currentOf(context);
    return Semantics(
      button: true,
      label: '${l10n.characterPackTitle}, ${pack.name(l10n)}',
      child: InkWell(
        onTap: () => context.push('/character-packs'),
        splashFactory: NoSplash.splashFactory,
        child: AppCard(
          child: LayoutBuilder(builder: (context, box) {
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.characterPackTitle, style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xxs),
                Text(pack.name(l10n), style: AppTextStyles.bodyStrong),
                const SizedBox(height: AppSpacing.sm),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  AppStatusBadge(
                    label: pack.ownedLabel(l10n),
                    tone: AppStatusBadgeTone.neutral,
                  ),
                  AppStatusBadge(
                    label: l10n.themeInUse,
                    tone: AppStatusBadgeTone.success,
                  ),
                ]),
              ],
            );
            final portrait = SizedBox(
              key: const Key('settings-current-pack-portrait'),
              width: 96,
              height: 104,
              child: CharacterPackPortrait(
                pack: pack,
                size: 96,
                animate: true,
              ),
            );
            final content = box.maxWidth < 260
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      portrait,
                      const SizedBox(height: AppSpacing.md),
                      details,
                    ],
                  )
                : Row(children: [
                    portrait,
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: details),
                    const AppIcon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                  ]);
            return Stack(
              children: [
                Positioned(
                  key: const Key('settings-pack-sky-decoration'),
                  left: -8,
                  top: -8,
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/decorations/progress-sky.png',
                      width: 126,
                      height: 79,
                      filterQuality: FilterQuality.none,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                Positioned(
                  key: const Key('settings-pack-sky-decoration-right'),
                  right: 10,
                  bottom: 4,
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/decorations/settings-card-cloud.png',
                      width: 70,
                      height: 35,
                      filterQuality: FilterQuality.none,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                content,
              ],
            );
          }),
        ),
      ),
    );
  }
}
