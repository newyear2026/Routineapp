import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_optional_provider.dart';
import '../application/store/pack_purchases.dart';
import '../data/store/store_product_catalog.dart';

import '../data/store/character_pack_catalog.dart';
import '../domain/store/character_pack.dart';
import '../domain/store/pack_ad_unlock.dart';
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
    final purchases = context.maybeWatch<PackPurchases>();
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
            // 스토어가 없는 곳(다른 플랫폼, 테스트)에서는 살 수 없는 카드를 두지
            // 않는다. 이미 산 사람에게는 산 것을 말하려고 남긴다.
            if (purchases != null &&
                (purchases.readiness != StoreReadiness.unavailable ||
                    purchases.ownsProduct(StoreProductCatalog.bundle))) ...[
              _BundleCard(purchases: purchases),
              const SizedBox(height: AppSpacing.xl),
            ],
            for (final pack in CharacterPackCatalog.all) ...[
              _PackListCard(
                pack: pack,
                inUse: pack.id == current.id,
                owned: ownership.owns(pack),
                adViews: CharacterPackScope.adViewsOf(context, pack),
                price: pack.productId == null
                    ? null
                    : purchases?.priceFor(pack.productId!),
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
    required this.adViews,
    required this.price,
    required this.onTap,
  });

  final CharacterPack pack;
  final bool inUse;
  final bool owned;

  /// 광고로 여는 중이면 끝까지 본 광고 수. 한 번이라도 봤으면 남은 만큼을
  /// 목록에서도 보인다 — 반쯤 연 팩을 잊지 않게.
  final int? adViews;

  /// 판매 팩의 현지 가격. 스토어가 아직 답하지 않았으면 null이다.
  final String? price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final watched = adViews ?? 0;
    final baseStatus = inUse
        ? l10n.themeInUse
        : owned
            ? pack.ownedLabel(l10n)
            : watched > 0
                ? l10n.characterPackAdUnlockProgress(
                    watched, RewardedUnlockOwnership.adsRequired)
                : price ?? pack.statusLabel(l10n);
    // 받은 선물이면 «출시 선물 · 보유 중». 받지 못했으면 상태 문구가 이미
    // «출시 선물»이라 앞머리를 붙이면 같은 말이 두 번 찍힌다.
    final status = pack.availability == CharacterPackAvailability.launchGift &&
            (inUse || owned)
        ? '${l10n.launchGiftBadge} · $baseStatus'
        : baseStatus;
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

/// «모든 팩 + 광고 제거». 판매 팩과 광고로 여는 팩, 광고 제거를 한 번에 판다.
class _BundleCard extends StatelessWidget {
  const _BundleCard({required this.purchases});

  final PackPurchases purchases;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const productId = StoreProductCatalog.bundle;
    final owned = purchases.ownsProduct(productId);
    final price = purchases.priceFor(productId);
    final buying = purchases.isBuying(productId);
    final pending = purchases.isPending(productId);
    return AppCard(
      variant: AppCardVariant.elevated,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.storeBundleTitle, style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.storeBundleDesc,
            style:
                AppTextStyles.captionTight.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          if (owned)
            Text(l10n.storeBundleOwned, style: AppTextStyles.caption)
          else ...[
            AppButton(
              label: price == null
                  ? l10n.characterPackOwnAction
                  : l10n.characterPackBuyAction(price),
              icon: Icons.shopping_bag_outlined,
              variant: AppButtonVariant.secondary,
              height: 48,
              isLoading: buying && !pending,
              onPressed: purchases.readiness == StoreReadiness.ready &&
                      price != null &&
                      !buying
                  ? () => purchases.buy(productId)
                  : null,
            ),
            if (pending) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.characterPackBuyPending,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
