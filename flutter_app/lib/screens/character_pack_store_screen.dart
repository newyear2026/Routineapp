import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_optional_provider.dart';
import '../application/store/pack_purchases.dart';
import '../data/store/character_pack_catalog.dart';
import '../data/store/store_product_catalog.dart';
import '../domain/store/character_pack.dart';
import '../domain/store/pack_ad_unlock.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_pixel_style.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/ds.dart';
import '../widgets/store/character_pack_preview.dart';
import '../widgets/store/character_pack_scene.dart';
import '../widgets/store/character_pack_scope.dart';
import '../widgets/store/character_pack_text.dart';

enum _PackTab { collection, store }

/// Owned characters open first; shopping has its own tab and scroll position.
class CharacterPackStoreScreen extends StatefulWidget {
  const CharacterPackStoreScreen({super.key});

  @override
  State<CharacterPackStoreScreen> createState() =>
      _CharacterPackStoreScreenState();
}

class _CharacterPackStoreScreenState extends State<CharacterPackStoreScreen> {
  _PackTab _tab = _PackTab.collection;
  String? _savingPack;

  void _showStore() => setState(() => _tab = _PackTab.store);

  Future<void> _apply(CharacterPack pack) async {
    final select = CharacterPackScope.onSelectOf(context);
    if (select == null || _savingPack != null) return;
    setState(() => _savingPack = pack.id);
    var saved = false;
    try {
      saved = await select(pack);
    } on Object {
      // Keep the previously applied character when persistence fails.
    }
    if (!mounted) return;
    setState(() => _savingPack = null);
    if (!saved) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content:
                Text(AppLocalizations.of(context).characterPackSelectFailed)));
    }
  }

  void _details(CharacterPack pack) =>
      context.push('/character-packs/${pack.id}');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = CharacterPackScope.currentOf(context);
    final ownership = CharacterPackScope.ownershipOf(context);
    final owned = CharacterPackCatalog.all.where(ownership.owns).toList();
    final purchases = context.maybeWatch<PackPurchases>();
    return Scaffold(
      body: AppScreenShell(
        backgroundColor: AppColors.decorationCream,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                IconButton(
                  tooltip: l10n.commonBack,
                  onPressed: () => context.pop(),
                  icon: const AppIcon(Icons.arrow_back_ios_new_rounded),
                ),
                Expanded(
                    child: Text(l10n.characterPackTitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleScreen)),
                const SizedBox(width: 48),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(children: [
                for (final tab in _PackTab.values)
                  Expanded(
                      child: _TabButton(
                    key: Key('pack-tab-${tab.name}'),
                    label: tab == _PackTab.collection
                        ? l10n.packCollectionTab
                        : l10n.packStoreTab,
                    selected: _tab == tab,
                    onTap: () => setState(() => _tab = tab),
                  )),
              ]),
            ),
            Expanded(
              child: ListView(
                key: PageStorageKey('packs-${_tab.name}'),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: _tab == _PackTab.collection
                    ? _collection(context, l10n, current, owned)
                    : _store(context, l10n, ownership, purchases),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _collection(BuildContext context, AppLocalizations l10n,
          CharacterPack current, List<CharacterPack> owned) =>
      [
        Text(l10n.packCollectionTitle, style: AppTextStyles.titleScreen),
        const SizedBox(height: 4),
        Text(l10n.packCollectionSubtitle, style: AppTextStyles.helper),
        const SizedBox(height: 16),
        _CurrentPackHero(pack: current),
        const SizedBox(height: 24),
        Text(l10n.packCollectionCount(owned.length),
            style: AppTextStyles.titleSection),
        const SizedBox(height: 12),
        _PackGrid(
          count: owned.length + (owned.length.isOdd ? 1 : 0),
          itemBuilder: (index, width) {
            if (index == owned.length) {
              return _DiscoverTile(onTap: _showStore);
            }
            final pack = owned[index];
            final inUse = current.id == pack.id;
            return _PackTile(
              key: Key('owned-pack-${pack.id}'),
              pack: pack,
              imageHeight: width * .59,
              selected: inUse,
              badge: pack.availability == CharacterPackAvailability.launchGift
                  ? l10n.launchGiftBadge
                  : null,
              onDetails: () => _details(pack),
              action: inUse
                  ? _OwnedStatus(label: l10n.themeInUse, selected: true)
                  : AppButton(
                      key: Key('apply-pack-${pack.id}'),
                      label: l10n.packApplyAction,
                      height: 44,
                      isLoading: _savingPack == pack.id,
                      variant: AppButtonVariant.secondary,
                      onPressed: _savingPack == null &&
                              pack.hasArtwork &&
                              CharacterPackScope.onSelectOf(context) != null
                          ? () => _apply(pack)
                          : null,
                    ),
            );
          },
        ),
        const SizedBox(height: 16),
        AppButton(
          key: const Key('discover-packs'),
          label: l10n.packDiscoverAction,
          icon: Icons.arrow_forward_rounded,
          variant: AppButtonVariant.secondary,
          onPressed: _showStore,
        ),
      ];

  List<Widget> _store(BuildContext context, AppLocalizations l10n,
      CharacterPackOwnership ownership, PackPurchases? purchases) {
    final sale = CharacterPackCatalog.all
        .where((pack) => pack.availability == CharacterPackAvailability.forSale)
        .toList();
    final rewards = CharacterPackCatalog.all.where((pack) =>
        pack.availability == CharacterPackAvailability.rewardedUnlock &&
        !ownership.owns(pack));
    Widget tile(CharacterPack pack, double width, {bool horizontal = false}) {
      final owned = ownership.owns(pack);
      final price = purchases?.priceFor(pack.productId!);
      final pending = purchases?.isPending(pack.productId!) ?? false;
      final busy = purchases?.isBuying(pack.productId!) ?? false;
      final ready =
          purchases?.readiness == StoreReadiness.ready && price != null;
      return _PackTile(
        key: Key('sale-pack-${pack.id}'),
        pack: pack,
        imageHeight: horizontal ? 126 : width * .59,
        horizontal: horizontal,
        onDetails: () => _details(pack),
        action: owned
            ? _OwnedStatus(label: l10n.characterPackOwned)
            : AppButton(
                label: price ?? l10n.packViewDetails,
                height: 44,
                variant: AppButtonVariant.secondary,
                isLoading: busy && !pending,
                // Details retain the existing checkout, pending and delivery flow.
                onPressed: busy ? null : () => _details(pack),
              ),
        status: pending
            ? l10n.characterPackBuyPending
            : !owned &&
                    !ready &&
                    purchases?.readiness != StoreReadiness.checking
                ? l10n.characterPackBuyUnavailable
                : null,
      );
    }

    return [
      Text(l10n.packStoreTitle, style: AppTextStyles.titleScreen),
      const SizedBox(height: 8),
      Text(l10n.packStoreContents, style: AppTextStyles.helper),
      const SizedBox(height: 4),
      Text(l10n.packStorePurchaseNote, style: AppTextStyles.helper),
      const SizedBox(height: 16),
      _PackGrid(
        count: sale.length.isOdd ? sale.length - 1 : sale.length,
        itemBuilder: (index, width) => tile(sale[index], width),
      ),
      if (sale.length.isOdd) ...[
        const SizedBox(height: 12),
        LayoutBuilder(
            builder: (context, constraints) => IntrinsicHeight(
                child: tile(sale.last, constraints.maxWidth,
                    horizontal:
                        MediaQuery.textScalerOf(context).scale(14) < 20 &&
                            constraints.maxWidth >= 310))),
      ],
      if (purchases != null &&
          (purchases.readiness != StoreReadiness.unavailable ||
              purchases.ownsProduct(StoreProductCatalog.bundle))) ...[
        const SizedBox(height: 16),
        _BundleCard(purchases: purchases),
      ],
      for (final pack in rewards) ...[
        const SizedBox(height: 16),
        _RewardPackRow(pack: pack, onTap: () => _details(pack)),
      ],
    ];
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        child: Material(
          color: selected
              ? AppColors.orbitHalo.withValues(alpha: .55)
              : Colors.transparent,
          shape: AppPixelStyle.shape(
              color: selected ? AppColors.orbitPrimary : AppColors.orbitBorder),
          child: InkWell(
            onTap: onTap,
            customBorder: AppPixelStyle.plainShape,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.control.copyWith(
                        color: selected
                            ? AppColors.orbitPrimary
                            : AppColors.textMuted)),
              ),
            ),
          ),
        ),
      );
}

class _CurrentPackHero extends StatelessWidget {
  const _CurrentPackHero({required this.pack});
  final CharacterPack pack;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return DecoratedBox(
      decoration: appSurfaceDecoration(),
      child: ClipPath(
        clipper: const ShapeBorderClipper(shape: AppPixelStyle.plainShape),
        child: CharacterPackScene(
          pack: pack,
          hero: true,
          height: 158 + (textScale - 1).clamp(0, 3) * 120,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
                builder: (context, constraints) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: constraints.maxWidth * .55,
                              child: Text(pack.name(l10n),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyStrong
                                      .copyWith(color: Colors.white))),
                          const SizedBox(height: 6),
                          SizedBox(
                              width: constraints.maxWidth * .52,
                              child: Text(pack.tagline(l10n),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption
                                      .copyWith(color: Colors.white))),
                          const Spacer(),
                          _OwnedStatus(
                              label: l10n.themeInUse,
                              selected: true,
                              compact: true),
                        ])),
          ),
        ),
      ),
    );
  }
}

/// Natural-height rows avoid clipping translated text and large accessibility text.
class _PackGrid extends StatelessWidget {
  const _PackGrid({required this.count, required this.itemBuilder});
  final int count;
  final Widget Function(int index, double width) itemBuilder;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 300 &&
                MediaQuery.textScalerOf(context).scale(14) < 20
            ? 2
            : 1;
        final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
        return Column(children: [
          for (var index = 0; index < count; index += columns) ...[
            if (index > 0) const SizedBox(height: 12),
            IntrinsicHeight(
                child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var offset = 0; offset < columns; offset++) ...[
                  if (offset > 0) const SizedBox(width: 12),
                  Expanded(
                      child: index + offset < count
                          ? itemBuilder(index + offset, width)
                          : const SizedBox.shrink()),
                ],
              ],
            )),
          ],
        ]);
      });
}

class _PackTile extends StatelessWidget {
  const _PackTile(
      {super.key,
      required this.pack,
      required this.imageHeight,
      required this.onDetails,
      required this.action,
      this.selected = false,
      this.horizontal = false,
      this.status,
      this.badge});
  final CharacterPack pack;
  final double imageHeight;
  final VoidCallback onDetails;
  final Widget action;
  final bool selected;
  final bool horizontal;
  final String? status;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final art = Stack(children: [
      CharacterPackScene(pack: pack, height: imageHeight),
      if (badge != null)
        Positioned(
            left: 5, top: 5, child: _OwnedStatus(label: badge!, compact: true)),
      if (selected)
        const Positioned(
            right: 6,
            top: 6,
            child: ColoredBox(
                color: AppColors.orbitPrimary,
                child: Padding(
                    padding: EdgeInsets.all(4),
                    child: AppIcon(Icons.check_rounded,
                        color: Colors.white, size: 18)))),
    ]);
    final copy = Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(pack.name(l10n), style: AppTextStyles.smallStrong),
            const SizedBox(height: 4),
            Text(pack.tagline(l10n), style: AppTextStyles.caption),
            if (status != null) ...[
              const SizedBox(height: 6),
              Text(status!, style: AppTextStyles.caption),
            ],
            if (!horizontal) const Spacer(),
            const SizedBox(height: 8),
            action,
          ]),
    );
    return Material(
      color: AppColors.decorationCream,
      clipBehavior: Clip.antiAlias,
      shape: AppPixelStyle.shape(
          color: selected ? AppColors.orbitPrimary : AppColors.orbitBorder,
          width: selected ? 2 : 1),
      child: InkWell(
        onTap: onDetails,
        child: horizontal
            ? Row(children: [
                Expanded(flex: 5, child: art),
                Expanded(flex: 5, child: copy)
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                art,
                Expanded(child: copy),
              ]),
      ),
    );
  }
}

class _OwnedStatus extends StatelessWidget {
  const _OwnedStatus(
      {required this.label, this.selected = false, this.compact = false});
  final String label;
  final bool selected;
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
        constraints: compact ? null : const BoxConstraints(minHeight: 44),
        alignment: compact ? null : Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: ShapeDecoration(
          color: selected ? AppColors.orbitHalo : AppColors.orbitSurfaceSoft,
          shape: AppPixelStyle.plainShape,
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: AppTextStyles.smallStrong.copyWith(
                color:
                    selected ? AppColors.orbitPrimary : AppColors.textMuted)),
      );
}

class _DiscoverTile extends StatelessWidget {
  const _DiscoverTile({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        shape: AppPixelStyle.shape(color: AppColors.orbitBorder),
        child: InkWell(
            onTap: onTap,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AppIcon(Icons.add_rounded,
                          size: 36, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(AppLocalizations.of(context).packDiscoverTile,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.helper),
                    ]))),
      );
}

class _RewardPackRow extends StatelessWidget {
  const _RewardPackRow({required this.pack, required this.onTap});
  final CharacterPack pack;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final watched = CharacterPackScope.adViewsOf(context, pack) ?? 0;
    return InkWell(
        onTap: onTap,
        child: AppCard(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            CharacterPackPortrait(pack: pack, size: 56),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(pack.name(l10n), style: AppTextStyles.smallStrong),
                  const SizedBox(height: 4),
                  Text(
                      watched > 0
                          ? l10n.characterPackAdUnlockProgress(
                              watched, RewardedUnlockOwnership.adsRequired)
                          : l10n.characterPackAdUnlockBadge,
                      style: AppTextStyles.caption),
                ])),
            const AppIcon(Icons.chevron_right_rounded),
          ]),
        ));
  }
}

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
      key: const Key('supporter-bundle-card'),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ClipPath(
          clipper: const ShapeBorderClipper(shape: AppPixelStyle.plainShape),
          child: AspectRatio(
            // Preserve the selected illustration's framing, including all five friends.
            aspectRatio: 1672 / 941,
            child: Image.asset(
              'assets/store/bundles/five_pack_forest_picnic.png',
              key: const Key('five-pack-forest-artwork'),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.low,
              excludeFromSemantics: true,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
            l10n.packBundleCountTitle(CharacterPackCatalog.all
                .where((pack) =>
                    StoreProductCatalog.grants[productId]!.contains(pack.id))
                .length),
            style: AppTextStyles.bodyStrong),
        const SizedBox(height: 4),
        Text(l10n.storeBundleDesc, style: AppTextStyles.caption),
        const SizedBox(height: 12),
        if (owned)
          _OwnedStatus(label: l10n.storeBundleOwned)
        else ...[
          AppButton(
            key: const Key('buy-pack-bundle'),
            label: price == null
                ? l10n.characterPackOwnAction
                : l10n.characterPackBuyAction(price),
            height: 48,
            isLoading: buying && !pending,
            onPressed: purchases.readiness == StoreReadiness.ready &&
                    price != null &&
                    !purchases.isBusy
                ? () => purchases.buy(productId)
                : null,
          ),
          if (pending || price == null) ...[
            const SizedBox(height: 8),
            Text(
                pending
                    ? l10n.characterPackBuyPending
                    : l10n.characterPackBuyUnavailable,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption),
          ],
        ],
      ]),
    );
  }
}
