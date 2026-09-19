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
import '../widgets/store/character_pack_text.dart';

/// 팩 하나를 파는 화면.
///
/// 결제는 아직 붙지 않았다. `BUSINESS_MODEL.md` 5장이 유료화의 전제로 둔
/// D30 리텐션 20%가 아직 없고, 가격도 스토어가 정한다. 그래서 구매 동작은
/// [CharacterPackOwnership] 자리만 남기고 비워 둔다 — 붙일 때 화면은
/// 건드리지 않는다.
class CharacterPackDetailScreen extends StatelessWidget {
  const CharacterPackDetailScreen({
    super.key,
    required this.packId,
    this.ownership = const BundledOnlyOwnership(),
  });

  final String packId;
  final CharacterPackOwnership ownership;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pack = CharacterPackCatalog.byId(packId);
    if (pack == null) {
      return Scaffold(
        body: AppScreenShell(
          child: Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: Text(l10n.commonGoBack),
            ),
          ),
        ),
      );
    }

    final owned = ownership.owns(pack);
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
                      l10n.characterPackKicker,
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pack.name(l10n),
              style: AppTextStyles.titleScreen,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              pack.tagline(l10n),
              style: AppTextStyles.helper,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Center(child: CharacterPackPortrait(pack: pack, size: 148)),
            const SizedBox(height: AppSpacing.xxl),
            _SectionLabel(l10n.characterPackContents),
            const SizedBox(height: AppSpacing.md),
            _ContentsRow(pack: pack),
            const SizedBox(height: AppSpacing.xxl),
            _SectionLabel(l10n.characterPackThemeColors),
            const SizedBox(height: AppSpacing.md),
            CharacterPackColorRow(pack: pack),
            const SizedBox(height: AppSpacing.xxl),
            _SectionLabel(l10n.characterPackDecoItems),
            const SizedBox(height: AppSpacing.md),
            CharacterPackDecoRow(pack: pack),
            const SizedBox(height: AppSpacing.huge),
            _PackAction(pack: pack, owned: owned),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.titleSection);
}

/// 시안의 «팩 구성 내용» 세 칸. 팩이 실제로 들고 있는 것만 센다.
class _ContentsRow extends StatelessWidget {
  const _ContentsRow({required this.pack});

  final CharacterPack pack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final slots = <(IconData, String, String)>[
      (
        Icons.emoji_emotions_outlined,
        l10n.characterPackSlotCharacter,
        l10n.characterPackSlotCharacterDesc,
      ),
      (
        Icons.animation_rounded,
        l10n.characterPackSlotPoses(CharacterPack.poseNames.length),
        l10n.characterPackSlotPosesDesc,
      ),
      (
        Icons.palette_outlined,
        l10n.characterPackSlotTheme,
        l10n.characterPackSlotThemeDesc,
      ),
    ];
    // 세 칸은 글자 길이가 달라도 같은 높이로 선다. ListView 안에서는 Row에
    // 높이 제약이 없어 stretch 만으로는 배치가 서지 않는다.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < slots.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(slots[i].$1,
                        size: 22, color: AppColors.orbitPrimary),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      slots[i].$2,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyStrong,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      slots[i].$3,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.captionTight
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 구매·사용 중 표시. **판정은 여기 한 곳에서만 한다.**
///
/// 조건이 화면 곳곳에 흩어지면 가격 정책을 바꿀 수 없게 된다
/// (`BUSINESS_MODEL.md` 6장).
class _PackAction extends StatelessWidget {
  const _PackAction({required this.pack, required this.owned});

  final CharacterPack pack;
  final bool owned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (owned) {
      return Center(
        child: AppStatusBadge(
          label: l10n.themeInUse,
          tone: AppStatusBadgeTone.success,
        ),
      );
    }
    final pending = pack.availability == CharacterPackAvailability.comingSoon;
    return Column(
      children: [
        AppButton(
          label: l10n.characterPackOwnAction,
          icon: Icons.lock_outline_rounded,
          // 결제가 붙기 전까지 누를 수 없다. 눌리는데 아무 일도 없는 버튼보다
          // 잠긴 채로 이유를 말하는 편이 낫다 (`PROJECT_RULES.md` 9장).
          onPressed: null,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          pending ? l10n.characterPackArtworkPending : l10n.commonComingSoon,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
