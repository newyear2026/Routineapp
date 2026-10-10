import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/domain/store/character_pack.dart';
import 'package:routine_timer/domain/store/purchase_ownership.dart';
import 'package:routine_timer/screens/character_pack_store_screen.dart';
import 'package:routine_timer/widgets/store/character_pack_scope.dart';

import 'support/localization.dart';

void main() {
  Widget host({
    required Set<String> entitlements,
    Future<bool> Function(CharacterPack)? select,
    double textScale = 1,
    Locale locale = testLocale,
  }) =>
      localizedApp(
          locale: locale,
          home: Builder(
              builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(textScale)),
                  child: CharacterPackScope(
                      current: CharacterPackCatalog.defaultPack,
                      ownership: PurchasedOwnership(
                          base: const BundledOnlyOwnership(),
                          entitlements: entitlements),
                      onSelect: select,
                      child: const CharacterPackStoreScreen()))));

  testWidgets(
      'applying an owned pack calls selection once and shows storage failure',
      (tester) async {
    final selected = <String>[];
    await tester.pumpWidget(host(
        entitlements: {'rabbit_postman'},
        select: (pack) async {
          selected.add(pack.id);
          return false;
        }));
    final apply = find.byKey(const Key('apply-pack-rabbit_postman'));
    await tester.scrollUntilVisible(apply, 250);
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(selected, ['rabbit_postman']);
    expect(find.text(testL10n.characterPackSelectFailed), findsOneWidget);
  });

  testWidgets(
      'new ownership is reflected in collection and refund removes the pack',
      (tester) async {
    await tester.pumpWidget(host(entitlements: {}));
    expect(find.byKey(const Key('owned-pack-rabbit_postman')), findsNothing);
    await tester.pumpWidget(host(entitlements: {'rabbit_postman'}));
    await tester.pump();
    expect(find.byKey(const Key('owned-pack-rabbit_postman')), findsOneWidget);
    await tester.tap(find.byKey(const Key('pack-tab-store')));
    await tester.pump();
    expect(
        find.descendant(
            of: find.byKey(const Key('sale-pack-rabbit_postman')),
            matching: find.text(testL10n.characterPackOwned)),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('pack-tab-collection')));
    await tester.pumpWidget(host(entitlements: {}));
    await tester.pump();
    expect(find.byKey(const Key('owned-pack-rabbit_postman')), findsNothing);
  });

  testWidgets(
      'discover opens store, collection has no purchase prices or unowned packs',
      (tester) async {
    await tester.pumpWidget(host(entitlements: {}));
    final discover = find.byKey(const Key('discover-packs'));
    await tester.scrollUntilVisible(discover, 200);
    await tester.tap(discover);
    await tester.pumpAndSettle();
    expect(find.text(testL10n.packStoreTitle), findsOneWidget);
    expect(find.byKey(const Key('sale-pack-rabbit_postman')), findsOneWidget);
    expect(find.text(testL10n.characterPackBuyUnavailable), findsWidgets);
    expect(find.textContaining('2,900'), findsNothing);
    await tester.tap(find.byKey(const Key('pack-tab-collection')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sale-pack-rabbit_postman')), findsNothing);
  });

  for (final locale in ['ko', 'en', 'es', 'ja', 'pt']) {
    testWidgets(
        '$locale at 320px and 2x text keeps both tabs and all actions reachable',
        (tester) async {
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(
          entitlements: {'rabbit_postman', 'cat_stargazer'},
          select: (_) async => true,
          textScale: 2,
          locale: Locale(locale)));
      await tester.pumpAndSettle();
      final apply = find.byKey(const Key('apply-pack-rabbit_postman'));
      await tester.scrollUntilVisible(apply, 250, maxScrolls: 35);
      await tester.pumpAndSettle();
      expect(apply, findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('pack-tab-store')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.byKey(const Key('sale-pack-otter_seaside')), 250,
          maxScrolls: 45);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
