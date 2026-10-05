import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/rewarded_ad_service.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/application/store/pack_purchases.dart';
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/data/store/store_product_catalog.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/domain/store/pack_ad_unlock.dart';
import 'package:routine_timer/screens/character_pack_detail_screen.dart';
import 'package:routine_timer/screens/character_pack_store_screen.dart';
import 'package:routine_timer/widgets/store/character_pack_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_purchase_backend.dart';
import 'support/localization.dart';
import 'support/test_doubles.dart';

const _rabbit = 'loopet.pack.rabbit_postman';
const _bundle = StoreProductCatalog.bundle;

class _MemoryAdViews implements PackAdUnlockStore {
  _MemoryAdViews([Map<String, int>? views]) : views = {...?views};

  final Map<String, int> views;

  @override
  Future<Map<String, int>> loadAdViews() async => {...views};

  @override
  Future<void> saveAdViews(String packId, int count) async =>
      views[packId] = count;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const homeWidgetChannel = MethodChannel('home_widget');

  late FakePurchaseBackend backend;
  late MemoryEntitlementStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, (call) async => true);
    backend = FakePurchaseBackend()
      ..catalogue = [
        productFor(_rabbit, r'$39.00'),
        productFor(_bundle, r'$89.00'),
      ];
    store = MemoryEntitlementStore();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, null);
  });

  Future<PackPurchases> startPurchases({bool restoreOnStart = false}) async {
    final purchases = PackPurchases(
      backend: backend,
      store: store,
      restoreOnStart: restoreOnStart,
      restoreGrace: const Duration(milliseconds: 20),
    );
    addTearDown(purchases.dispose);
    await purchases.start();
    return purchases;
  }

  Future<RoutineAppController> loadController(
    PackPurchases purchases, {
    PackAdUnlockStore? adViews,
  }) async {
    final controller = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: MemoryRoutineRepository(const []),
        logRepository: MemoryLogRepository(),
      ),
      notificationService: RoutineNotificationService(
        exactAlarmsAllowed: () async => false,
        gateway: NoopNotificationGateway(),
        preferencesLoader: () async =>
            NotificationPreferences.firstLaunchDefaults,
      ),
      purchases: purchases,
      packAdUnlockStore: adViews ?? _MemoryAdViews(),
      rewardedPackUnlocks: true,
      showRewardedAd: (_) async => RewardedAdOutcome.earned,
      nowProvider: () => DateTime(2026, 9, 30, 10),
      clockAutoRefreshEnabled: false,
    );
    addTearDown(controller.dispose);
    await controller.load();
    return controller;
  }

  group('소유 판정', () {
    test('산 팩은 결제가 끝나는 순간 소유가 되고 고를 수 있다', () async {
      final purchases = await startPurchases();
      final controller = await loadController(purchases);
      const rabbit = CharacterPackCatalog.postmanRabbit;
      var notified = 0;
      controller.addListener(() => notified++);

      expect(controller.packOwnership.owns(rabbit), isFalse);
      expect(await controller.selectCharacterPack(rabbit), isFalse);

      await purchases.buy(_rabbit);
      backend.emit([detailsFor(_rabbit, PurchaseStatus.purchased)]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.packOwnership.owns(rabbit), isTrue);
      expect(notified, greaterThan(0));
      expect(await controller.selectCharacterPack(rabbit), isTrue);
      expect(controller.currentPack.id, rabbit.id);
    });

    test('가격이 도착하는 것만으로는 소유 판정을 다시 만들지 않는다', () async {
      final purchases = PackPurchases(
        backend: backend,
        store: store,
        restoreOnStart: false,
      );
      addTearDown(purchases.dispose);
      final controller = await loadController(purchases);
      final before = controller.packOwnership;
      await purchases.start();
      expect(identical(controller.packOwnership, before), isTrue);
    });

    test('번들을 환불해도 광고를 보고 연 푸들은 남는다', () async {
      store.saved = {...StoreProductCatalog.grants[_bundle]!};
      backend.paidProductIds = {};
      final purchases = await startPurchases(restoreOnStart: true);
      final controller = await loadController(
        purchases,
        adViews: _MemoryAdViews({
          'poodle_garden': RewardedUnlockOwnership.adsRequired,
        }),
      );

      expect(purchases.adFree, isFalse);
      expect(controller.packOwnership.owns(CharacterPackCatalog.postmanRabbit),
          isFalse);
      expect(controller.packOwnership.owns(CharacterPackCatalog.poodleGarden),
          isTrue);
    });
  });

  Widget app(
      RoutineAppController controller, PackPurchases purchases, Widget home) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: purchases),
        ChangeNotifierProvider.value(value: controller),
      ],
      child: localizedApp(
        home: Consumer<RoutineAppController>(
          builder: (context, app, _) => CharacterPackScope(
            current: app.currentPack,
            ownership: app.packOwnership,
            onSelect: app.selectCharacterPack,
            adViews: app.packAdViews,
            onWatchAd: app.watchAdForPackUnlock,
            child: home,
          ),
        ),
      ),
    );
  }

  group('팩 상세', () {
    testWidgets('판매 팩은 현지 가격으로 사고, 결제가 끝나면 바로 입힌다', (tester) async {
      tester.view.physicalSize = const Size(430, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late PackPurchases purchases;
      late RoutineAppController controller;
      await tester.runAsync(() async {
        purchases = await startPurchases();
        controller = await loadController(purchases);
      });
      await tester.pumpWidget(app(controller, purchases,
          const CharacterPackDetailScreen(packId: 'rabbit_postman')));
      await tester.pump();

      final buy = find.text(testL10n.characterPackBuyAction(r'$39.00'));
      expect(buy, findsOneWidget);
      await tester.tap(buy);
      await tester.pump();
      expect(backend.bought, [_rabbit]);

      await tester.runAsync(() async {
        backend.emit([detailsFor(_rabbit, PurchaseStatus.purchased)]);
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();

      expect(controller.currentPack.id, 'rabbit_postman');
      expect(find.text(testL10n.themeInUse), findsOneWidget);
    });

    testWidgets('스토어가 없으면 살 수 없다고 말하고 버튼을 잠근다', (tester) async {
      tester.view.physicalSize = const Size(430, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      backend.available = false;
      late PackPurchases purchases;
      late RoutineAppController controller;
      await tester.runAsync(() async {
        purchases = await startPurchases();
        controller = await loadController(purchases);
      });
      await tester.pumpWidget(app(controller, purchases,
          const CharacterPackDetailScreen(packId: 'rabbit_postman')));
      await tester.pump();

      expect(find.text(testL10n.characterPackBuyUnavailable), findsOneWidget);
      await tester.tap(find.text(testL10n.characterPackOwnAction));
      await tester.pump();
      expect(backend.bought, isEmpty);
    });

    testWidgets('Play 구매창에서 뒤로 가면 로딩을 끝내고 다시 구매할 수 있다', (tester) async {
      tester.view.physicalSize = const Size(430, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late PackPurchases purchases;
      late RoutineAppController controller;
      await tester.runAsync(() async {
        purchases = await startPurchases();
        controller = await loadController(purchases);
      });
      await tester.pumpWidget(app(controller, purchases,
          const CharacterPackDetailScreen(packId: 'rabbit_postman')));
      await tester.pump();

      final buy = find.text(testL10n.characterPackBuyAction(r'$39.00'));
      await tester.tap(buy);
      await tester.pump();
      expect(backend.bought, [_rabbit]);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Play의 뒤로 가기 응답에는 상품 ID가 없다.
      await tester.runAsync(() async {
        backend.emit([
          detailsFor('', PurchaseStatus.canceled, needsCompleting: false),
        ]);
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(purchases.isBusy, isFalse);
      expect(purchases.entitlements, isEmpty);
      expect(purchases.takeFailure(), isNull);
      await tester.tap(buy);
      await tester.pump();
      expect(backend.bought, [_rabbit, _rabbit]);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.runAsync(() async {
        backend.emit([
          detailsFor('', PurchaseStatus.canceled, needsCompleting: false),
        ]);
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('팩 목록', () {
    testWidgets('구매 완료한 팩은 내 캐릭터에 추가되고 목록에서 바로 적용한다', (tester) async {
      late PackPurchases purchases;
      late RoutineAppController controller;
      await tester.runAsync(() async {
        purchases = await startPurchases();
        controller = await loadController(purchases);
      });
      await tester.pumpWidget(
          app(controller, purchases, const CharacterPackStoreScreen()));
      await tester.pump();
      expect(find.byKey(const Key('owned-pack-rabbit_postman')), findsNothing);
      await tester.tap(find.byKey(const Key('pack-tab-store')));
      await tester.runAsync(() async {
        backend.emit([detailsFor(_rabbit, PurchaseStatus.purchased)]);
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pumpAndSettle();
      expect(
          find.descendant(
              of: find.byKey(const Key('sale-pack-rabbit_postman')),
              matching: find.text(testL10n.characterPackOwned)),
          findsOneWidget);
      await tester.tap(find.byKey(const Key('pack-tab-collection')));
      await tester.pumpAndSettle();
      final apply = find.byKey(const Key('apply-pack-rabbit_postman'));
      await tester.scrollUntilVisible(apply, 250);
      await tester.runAsync(() async {
        await tester.tap(apply);
      });
      await tester.pumpAndSettle();
      expect(controller.currentPack.id, 'rabbit_postman');
      expect(find.byKey(const Key('apply-pack-rabbit_postman')), findsNothing);
    });

    testWidgets('번들 카드가 가격과 함께 있고, 판매 팩 딱지는 가격이다', (tester) async {
      tester.view.physicalSize = const Size(430, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late PackPurchases purchases;
      late RoutineAppController controller;
      await tester.runAsync(() async {
        purchases = await startPurchases();
        controller = await loadController(purchases);
      });
      await tester.pumpWidget(
          app(controller, purchases, const CharacterPackStoreScreen()));
      await tester.pump();

      await tester.tap(find.byKey(const Key('pack-tab-store')));
      await tester.pumpAndSettle();
      expect(find.text(testL10n.packBundleCountTitle(5)), findsOneWidget);
      expect(find.text(r'$39.00'), findsOneWidget);
      await tester.tap(find.text(testL10n.characterPackBuyAction(r'$89.00')));
      await tester.pump();
      expect(backend.bought, [_bundle]);

      // 결제 창을 닫는다. 열린 채로 두면 결제 기한 타이머가 남는다.
      await tester.runAsync(() async {
        backend.emit([
          detailsFor('', PurchaseStatus.canceled, needsCompleting: false),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      expect(purchases.isBuying(_bundle), isFalse);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('스토어가 없으면 번들 카드를 두지 않는다', (tester) async {
      backend.available = false;
      late PackPurchases purchases;
      late RoutineAppController controller;
      await tester.runAsync(() async {
        purchases = await startPurchases();
        controller = await loadController(purchases);
      });
      await tester.pumpWidget(
          app(controller, purchases, const CharacterPackStoreScreen()));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pack-tab-store')));
      await tester.pumpAndSettle();
      expect(find.text(testL10n.packBundleCountTitle(5)), findsNothing);
    });

    testWidgets('5종 묶음 결제 뒤 내 캐릭터에 다섯 팩이 추가되고 푸들은 광고로 연다', (tester) async {
      tester.view
        ..physicalSize = const Size(430, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late PackPurchases purchases;
      late RoutineAppController controller;
      await tester.runAsync(() async {
        purchases = await startPurchases();
        controller = await loadController(purchases);
      });
      await tester.pumpWidget(
          app(controller, purchases, const CharacterPackStoreScreen()));
      await tester.tap(find.byKey(const Key('pack-tab-store')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('buy-pack-bundle')));
      await tester.runAsync(() async {
        backend.emit([detailsFor(_bundle, PurchaseStatus.purchased)]);
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pumpAndSettle();
      expect(backend.bought, [_bundle]);
      expect(purchases.adFree, isTrue);
      expect(find.text(testL10n.storeBundleOwned), findsOneWidget);
      expect(controller.packOwnership.owns(CharacterPackCatalog.poodleGarden),
          isFalse);
      // 새 광고 팩이 추가되어도 이 테스트는 푸들의 잠금 상태를 확인한다.
      expect(
          find.descendant(
            of: find.ancestor(
              of: find.text(testL10n.packPoodleGardenName),
              matching: find.byType(InkWell),
            ).first,
            matching: find.text(testL10n.characterPackAdUnlockBadge),
          ),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('pack-tab-collection')));
      await tester.pumpAndSettle();
      for (final id in StoreProductCatalog.bundlePackIds) {
        expect(find.byKey(Key('owned-pack-$id')), findsOneWidget);
      }
      expect(find.byKey(const Key('owned-pack-poodle_garden')), findsNothing);
    });
  });
}
