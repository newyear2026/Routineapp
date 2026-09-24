import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/store/character_pack_catalog.dart';
import '../domain/store/character_pack.dart';
import '../domain/store/pack_trial.dart';
import '../domain/utils/app_date_formats.dart';
import '../domain/utils/time_minutes.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/ds.dart';
import '../widgets/ds/pixel_decoration.dart';
import '../widgets/store/character_pack_preview.dart';
import '../widgets/store/character_pack_scope.dart';
import '../widgets/store/character_pack_text.dart';

/// 팩 하나를 보여 주고, 가진 팩이면 쓰게 하고, 아니면 파는 화면.
///
/// 결제는 아직 붙지 않았다. `BUSINESS_MODEL.md` 5장이 유료화의 전제로 둔
/// D30 리텐션 20%가 아직 없고, 가격도 스토어가 정한다. 그래서 구매 동작은
/// [CharacterPackOwnership] 자리만 남기고 비워 둔다 — 붙일 때 화면은
/// 건드리지 않는다.
class CharacterPackDetailScreen extends StatelessWidget {
  const CharacterPackDetailScreen({super.key, required this.packId});

  final String packId;

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

    final ownership = CharacterPackScope.ownershipOf(context);
    final inUse = CharacterPackScope.currentOf(context).id == pack.id;
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
            Center(
              child: SizedBox(
                width: 210,
                height: 166,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    if (pack.id == CharacterPackCatalog.poodleGarden.id) ...[
                      const Positioned(
                        left: 0,
                        top: 2,
                        child: GardenLeaf(
                          key: Key('poodle-detail-leaf-left-top'),
                          size: 28,
                          angle: -0.2,
                        ),
                      ),
                      const Positioned(
                        right: 1,
                        top: 12,
                        child: GardenLeaf(
                          key: Key('poodle-detail-leaf-right-top'),
                          size: 25,
                          mirror: true,
                        ),
                      ),
                      const Positioned(
                        left: 14,
                        bottom: 55,
                        child: GardenLeaf(size: 20, mirror: true),
                      ),
                      const Positioned(
                        right: 13,
                        bottom: 58,
                        child: GardenLeaf(size: 21, angle: 0.5),
                      ),
                      const Positioned(
                        right: 0,
                        bottom: 4,
                        child: PixelDecoration(
                          asset: 'garden-daisy',
                          size: 58,
                        ),
                      ),
                    ],
                    CharacterPackPortrait(pack: pack, size: 148),
                  ],
                ),
              ),
            ),
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
            _PackAction(
              pack: pack,
              inUse: inUse,
              owned: ownership.owns(pack),
              selectable: CharacterPackCatalog.isSelectable(pack, ownership),
              trialEndsAt: CharacterPackScope.trialEndsAtOf(context, pack),
              onSelect: CharacterPackScope.onSelectOf(context),
              onStartTrial: CharacterPackScope.onStartTrialOf(context),
            ),
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

/// 사용 중 · 쓰기 · 광고로 체험 · 구매 표시. **판정은 여기 한 곳에서만 한다.**
///
/// 조건이 화면 곳곳에 흩어지면 가격 정책을 바꿀 수 없게 된다
/// (`BUSINESS_MODEL.md` 6장).
class _PackAction extends StatefulWidget {
  const _PackAction({
    required this.pack,
    required this.inUse,
    required this.owned,
    required this.selectable,
    required this.trialEndsAt,
    required this.onSelect,
    required this.onStartTrial,
  });

  final CharacterPack pack;
  final bool inUse;
  final bool owned;
  final bool selectable;

  /// 광고로 체험 중이면 끝나는 시각.
  final DateTime? trialEndsAt;
  final Future<bool> Function(CharacterPack pack)? onSelect;
  final Future<PackTrialOutcome> Function(CharacterPack pack)? onStartTrial;

  @override
  State<_PackAction> createState() => _PackActionState();
}

class _PackActionState extends State<_PackAction> {
  bool _saving = false;

  Future<void> _select() async {
    final onSelect = widget.onSelect;
    if (onSelect == null || _saving) return;
    final messenger = ScaffoldMessenger.of(context);
    final failureMessage =
        AppLocalizations.of(context).characterPackSelectFailed;
    setState(() => _saving = true);
    final saved = await onSelect(widget.pack);
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failureMessage)));
  }

  Future<void> _startTrial() async {
    final onStartTrial = widget.onStartTrial;
    if (onStartTrial == null || _saving) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    final outcome = await onStartTrial(widget.pack);
    if (!mounted) return;
    setState(() => _saving = false);
    // 성공하면 알리지 않는다. 버튼이 «사용 중»으로 바뀌고 캐릭터가 바뀌는
    // 것이 곧 결과다.
    final message = switch (outcome) {
      PackTrialOutcome.started => null,
      PackTrialOutcome.adNotCompleted => l10n.characterPackTrialNotCompleted,
      PackTrialOutcome.dailyLimitReached => l10n.characterPackTrialDailyLimit,
      PackTrialOutcome.adUnavailable => l10n.characterPackTrialUnavailable,
      PackTrialOutcome.failed => l10n.characterPackSelectFailed,
    };
    if (message == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// 체험이 끝나는 때 — 내일 이맘때라 날짜까지 적는다.
  Widget? _trialCaption(AppLocalizations l10n) {
    final end = widget.trialEndsAt;
    if (end == null) return null;
    final when = '${AppDateFormats.monthDay(context, end)} '
        '${TimeMinutes.formatHm(end.hour * 60 + end.minute)}';
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        l10n.characterPackTrialEndsAt(when),
        textAlign: TextAlign.center,
        style: AppTextStyles.caption,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trialCaption = _trialCaption(l10n);
    if (widget.inUse) {
      return Column(
        children: [
          Center(
            child: AppStatusBadge(
              label: l10n.themeInUse,
              tone: AppStatusBadgeTone.success,
            ),
          ),
          if (trialCaption != null) trialCaption,
        ],
      );
    }
    if (widget.owned) {
      return Column(
        children: [
          AppButton(
            label: l10n.characterPackUseAction,
            icon: Icons.check_rounded,
            isLoading: _saving,
            onPressed:
                widget.selectable && widget.onSelect != null ? _select : null,
          ),
          if (trialCaption != null) trialCaption,
          // 산 팩이라도 그림이 오기 전에는 쓸 수 없다. 잠긴 이유를 말한다
          // (`PROJECT_RULES.md` 9장).
          if (!widget.pack.hasArtwork) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.characterPackArtworkPending,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ],
      );
    }
    if (widget.pack.availability == CharacterPackAvailability.rewardedTrial) {
      return Column(
        children: [
          AppButton(
            label: l10n.characterPackTrialAction,
            icon: Icons.play_circle_outline_rounded,
            isLoading: _saving,
            onPressed: widget.onStartTrial != null ? _startTrial : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          // 무엇을 내고 무엇을 받는지 누르기 전에 말한다. 보상형 광고 정책도
          // 보상 내용을 미리 알리도록 요구한다.
          Text(
            l10n.characterPackTrialHint,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      );
    }
    final pending =
        widget.pack.availability == CharacterPackAvailability.comingSoon;
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
