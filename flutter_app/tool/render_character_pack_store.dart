// flutter test tool/render_character_pack_store.dart --dart-define=PREVIEW_FONT=/System/Library/Fonts/AppleSDGothicNeo.ttc
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/store/pack_purchases.dart';
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/data/store/store_product_catalog.dart';
import 'package:routine_timer/domain/store/character_pack.dart';
import 'package:routine_timer/domain/store/purchase_ownership.dart';
import 'package:routine_timer/screens/character_pack_store_screen.dart';
import 'package:routine_timer/theme/app_theme.dart';
import 'package:routine_timer/widgets/store/character_pack_scope.dart';
import '../test/support/fake_purchase_backend.dart';
import '../test/support/localization.dart';

void main() {
  testWidgets('Render collection and store with actual bundled art',
      (tester) async {
    const font = String.fromEnvironment('PREVIEW_FONT');
    await (FontLoader('PreviewKorean')
          ..addFont(
              Future.value(ByteData.sublistView(File(font).readAsBytesSync()))))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    final backend = FakePurchaseBackend()
      ..catalogue = [
        for (final id in StoreProductCatalog.productIds)
          productFor(
              id, id == StoreProductCatalog.bundle ? '₩6,900' : '₩2,900'),
      ];
    final purchases = PackPurchases(
        backend: backend,
        store: MemoryEntitlementStore({'rabbit_postman'}),
        restoreOnStart: false);
    await purchases.start();
    addTearDown(purchases.dispose);
    addTearDown(backend.close);
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    var current = CharacterPackCatalog.defaultPack;
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: purchases,
        child: localizedApp(
            theme: buildRoutineTheme(fontFamily: 'PreviewKorean'),
            home: StatefulBuilder(
                builder: (context, setState) => CharacterPackScope(
                      current: current,
                      ownership: PurchasedOwnership(
                          base: const BundledOnlyOwnership(),
                          entitlements: {'rabbit_postman', 'cat_stargazer'}),
                      onSelect: (pack) async {
                        setState(() => current = pack);
                        return true;
                      },
                      child: RepaintBoundary(
                          key: key, child: const CharacterPackStoreScreen()),
                    )))));
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        for (var i = 0; i < 3; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 80));
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        return data!.buffer.asUint8List();
      });
      File('design/character-pack-store/$name.png').writeAsBytesSync(bytes!);
    }

    await capture('collection');
    await tester.tap(find.byKey(const Key('pack-tab-store')));
    await tester.pumpAndSettle();
    await capture('store');
    await tester.scrollUntilVisible(
        find.byKey(const Key('supporter-bundle-card')), 300);
    await tester.ensureVisible(find.byKey(const Key('supporter-bundle-card')));
    await tester.pumpAndSettle();
    await capture('store-bottom');
    // Taller captures record the entire composition, in addition to real viewports.
    tester.view.physicalSize = const Size(390, 1600);
    await tester.drag(find.byType(ListView), const Offset(0, 2400));
    await tester.pumpAndSettle();
    await capture('store-full');
    tester.view.physicalSize = const Size(390, 1150);
    await tester.tap(find.byKey(const Key('pack-tab-collection')));
    await tester.pumpAndSettle();
    await capture('collection-full');

    // Check that the illustrated card still leads to checkout on a small phone.
    await tester.tap(find.byKey(const Key('pack-tab-store')));
    tester.view.physicalSize = const Size(320, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    final buy = find.byKey(const Key('buy-pack-bundle'));
    await tester.scrollUntilVisible(buy, 250, maxScrolls: 30);
    await tester.pumpAndSettle();
    expect(buy.hitTestable(), findsOneWidget);
    await capture('store-bundle-large-text');
  });
}
