import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/store/character_pack_catalog.dart';
import '../domain/store/character_pack.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/ds.dart';
import '../widgets/store/character_pack_preview.dart';
import '../widgets/store/character_pack_scope.dart';
import '../widgets/store/character_pack_text.dart';

/// 캐릭터 팩 목록 — 설정의 외형 항목이 모두 여기로 모인다.
///
/// 캐릭터와 테마를 각각 고르는 자리를 따로 두지 않는다. 파는 단위가 팩이면
/// 고르는 단위도 팩이어야 하고, 그렇지 않으면 산 것과 고르는 것의 모양이
/// 달라진다.
class CharacterPackStoreScreen extends StatelessWidget {
  const CharacterPackStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = CharacterPackScope.currentOf(context);
    final ownership = CharacterPackScope.ownershipOf(context);
    return Scaffold(
      body: AppScreenShell(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.commonBack,
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.textPrimary,
                  ),
                  Expanded(
                    child: Text(
                      l10n.characterPackTitle,
                      style: AppTextStyles.titleScreen,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.characterPackSubtitle, style: AppTextStyles.helper),
            const SizedBox(height: AppSpacing.xxl),
            for (final pack in CharacterPackCatalog.all) ...[
              _PackListCard(
                pack: pack,
                inUse: pack.id == current.id,
                owned: ownership.owns(pack),
                onTap: () => context.push('/character-packs/${pack.id}'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _PackListCard extends StatelessWidget {
  const _PackListCard({
    required this.pack,
    required this.inUse,
    required this.owned,
    required this.onTap,
  });

  final CharacterPack pack;
  final bool inUse;
  final bool owned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = inUse
        ? l10n.themeInUse
        : owned
            ? pack.ownedLabel(l10n)
            : pack.statusLabel(l10n);
    return Semantics(
      button: true,
      label: '${pack.name(l10n)}, $status',
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        child: AppCard(
          child: Row(
            children: [
              CharacterPackPortrait(pack: pack, size: 76),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(pack.name(l10n), style: AppTextStyles.bodyStrong),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      pack.tagline(l10n),
                      style: AppTextStyles.captionTight
                          .copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppStatusBadge(
                      label: status,
                      tone: inUse
                          ? AppStatusBadgeTone.success
                          : AppStatusBadgeTone.neutral,
                    ),
                  ],
                ),
              ),
              const AppIcon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
