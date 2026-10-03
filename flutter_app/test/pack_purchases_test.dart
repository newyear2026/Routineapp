import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:routine_timer/application/store/pack_purchases.dart';
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/data/store/store_product_catalog.dart';

import 'support/fake_purchase_backend.dart';

const _rabbit = 'loopet.pack.rabbit_postman';
const _squirrel = 'loopet.pack.squirrel_explorer';
const _sheep = 'loopet.pack.sheep_mooncloud';
const _bundle = StoreProductCatalog.bundle;

void main() {
  late FakePurchaseBackend backend;
  late MemoryEntitlementStore store;

  setUp(() {
    backend = FakePurchaseBackend()
      ..catalogue = [
        productFor(_rabbit, r'$39.00'),
        productFor(_squirrel, r'$39.00'),
        productFor(_sheep, r'$39.00'),
        productFor(_bundle, r'$89.00'),
      ];
    store = MemoryEntitlementStore();
  });
  tearDown(() => backend.close());

  PackPurchases purchases({
    bool restoreOnStart = true,
    Duration restoreGrace = const Duration(milliseconds: 50),
    Duration checkoutTimeout = const Duration(minutes: 3),
  }) {
    final result = PackPurchases(
      backend: backend,
      store: store,
      restoreOnStart: restoreOnStart,
      restoreGrace: restoreGrace,
      checkoutTimeout: checkoutTimeout,
    );
    addTearDown(result.dispose);
    return result;
  }

  /// 스트림 처리와 저장이 끝나기를 기다린다.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('상품 표', () {
    test('판매 팩마다 단품이 있고, 번들은 지정한 5종과 광고 제거만 준다', () {
      final grants = StoreProductCatalog.grants;
      expect(grants[_rabbit], {'rabbit_postman'});
      expect(grants[_squirrel], {'squirrel_explorer'});
      expect(grants[_sheep], {'sheep_mooncloud'});
      expect(grants[_bundle], {
        'rabbit_postman',
        'squirrel_explorer',
        'sheep_mooncloud',
        'redpanda_teashop',
        'otter_seaside',
        StoreProductCatalog.adFree,
      });
    });

    test('출시 선물·기본 제공·광고 팩은 어떤 상품으로도 팔지 않는다', () {
      final sold = StoreProductCatalog.grants.values.expand((ids) => ids);
      expect(sold, isNot(contains(CharacterPackCatalog.stargazerCat.id)));
      expect(sold, isNot(contains(CharacterPackCatalog.starlightCat.id)));
      expect(sold, isNot(contains(CharacterPackCatalog.penguinSnowWalk.id)));
      expect(StoreProductCatalog.productIds,
          isNot(contains('loopet.pack.penguin_snow_walk')));
    });
  });

  test('저장된 권리를 읽고 가격을 받는다', () async {
    store.saved = {'rabbit_postman'};
    final p = purchases(restoreOnStart: false);
    await p.start();

    expect(p.readiness, StoreReadiness.ready);
    expect(p.entitlements, {'rabbit_postman'});
    expect(p.priceFor(_squirrel), r'$39.00');
    expect(p.ownsProduct(_rabbit), isTrue);
  });

  test('스토어가 없으면 가격 없이 준비 안 됨이고, 사려 하면 그렇다고 말한다', () async {
    backend.available = false;
    final p = purchases();
    await p.start();

    expect(p.readiness, StoreReadiness.unavailable);
    expect(p.priceFor(_rabbit), isNull);
    await p.buy(_rabbit);
    expect(p.takeFailure(), PurchaseFailure.storeUnavailable);
    expect(backend.bought, isEmpty);
  });

  test('결제가 끝나면 지급한 뒤에 완료한다', () async {
    final p = purchases(restoreOnStart: false);
    await p.start();
    Set<String>? ownedAtCompletion;
    backend.onComplete = (_) => ownedAtCompletion = {...p.entitlements};

    await p.buy(_rabbit);
    expect(p.isBuying(_rabbit), isTrue);
    backend.emit([detailsFor(_rabbit, PurchaseStatus.purchased)]);
    await settle();

    expect(p.entitlements, {'rabbit_postman'});
    expect(store.saved, {'rabbit_postman'});
    expect(backend.completed, [_rabbit]);
    expect(ownedAtCompletion, contains('rabbit_postman'),
        reason: '완료보다 지급이 먼저여야 한다');
    expect(p.isBuying(_rabbit), isFalse);
  });

  test('번들을 사면 5종과 광고 제거를 저장하고 푸들은 지급하지 않는다', () async {
    final p = purchases(restoreOnStart: false);
    await p.start();
    await p.buy(_bundle);
    backend.emit([detailsFor(_bundle, PurchaseStatus.purchased)]);
    await settle();

    expect(p.adFree, isTrue);
    expect(p.entitlements, {
      'rabbit_postman',
      'squirrel_explorer',
      'sheep_mooncloud',
      'redpanda_teashop',
      'otter_seaside',
      StoreProductCatalog.adFree,
    });
    expect(store.saved, p.entitlements);
    expect(p.ownsProduct(_bundle), isTrue);
    expect(p.ownsProduct(_rabbit), isTrue, reason: '번들이 단품을 덮는다');
  });

  test('새 설치에서 번들을 복원해도 같은 5종과 광고 제거만 받는다', () async {
    backend.ownedProductIds = [_bundle];
    final p = purchases();
    await p.start();
    await settle();
    expect(p.entitlements, {
      'rabbit_postman',
      'squirrel_explorer',
      'sheep_mooncloud',
      'redpanda_teashop',
      'otter_seaside',
      StoreProductCatalog.adFree,
    });
    expect(p.ownsProduct(_bundle), isTrue);
    expect(store.saved, p.entitlements);
  });

  test('이미 다 가진 상품은 결제 창을 열지 않는다', () async {
    store.saved = {'rabbit_postman'};
    final p = purchases(restoreOnStart: false);
    await p.start();
    await p.buy(_rabbit);
    expect(backend.bought, isEmpty);
  });

  test('결제 창이 열린 동안 두 번째 탭은 무시한다', () async {
    final p = purchases(restoreOnStart: false);
    await p.start();
    await p.buy(_rabbit);
    await p.buy(_rabbit);
    expect(backend.bought, [_rabbit]);
  });

  test('취소는 아무것도 주지 않고 아무 말도 하지 않는다', () async {
    final p = purchases(restoreOnStart: false);
    await p.start();
    await p.buy(_rabbit);
    backend.emit([detailsFor(_rabbit, PurchaseStatus.canceled)]);
    await settle();

    expect(p.entitlements, isEmpty);
    expect(p.takeFailure(), isNull);
    expect(p.isBuying(_rabbit), isFalse);
  });

  test('거절된 결제는 한 번만 알린다', () async {
    final p = purchases(restoreOnStart: false);
    await p.start();
    await p.buy(_rabbit);
    backend.emit([detailsFor(_rabbit, PurchaseStatus.error)]);
    await settle();

    expect(p.takeFailure(), PurchaseFailure.purchaseRejected);
    expect(p.takeFailure(), isNull);
  });

  test('Play가 쥔 대기 결제는 팩을 잠근 채 기한 없이 기다린다', () async {
    final p = purchases(
      restoreOnStart: false,
      checkoutTimeout: const Duration(milliseconds: 10),
    );
    await p.start();
    await p.buy(_rabbit);
    backend.emit([detailsFor(_rabbit, PurchaseStatus.pending)]);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(p.entitlements, isEmpty);
    expect(p.isPending(_rabbit), isTrue);
    expect(p.isBuying(_rabbit), isTrue);

    backend.emit([detailsFor(_rabbit, PurchaseStatus.purchased)]);
    await settle();
    expect(p.entitlements, {'rabbit_postman'});
    expect(p.isPending(_rabbit), isFalse);
  });

  test('아무 답도 없는 결제 창은 기한이 지나면 버튼을 돌려준다', () async {
    final p = purchases(
      restoreOnStart: false,
      checkoutTimeout: const Duration(milliseconds: 10),
    );
    await p.start();
    await p.buy(_rabbit);
    expect(p.isBuying(_rabbit), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(p.isBuying(_rabbit), isFalse);
  });

  group('저장이 실패하면', () {
    test('알리고, 완료하지 않아 다음 실행에 다시 받는다', () async {
      store.failSave = true;
      final p = purchases(restoreOnStart: false);
      await p.start();
      await p.buy(_rabbit);
      backend.emit([detailsFor(_rabbit, PurchaseStatus.purchased)]);
      await settle();

      expect(p.takeFailure(), PurchaseFailure.deliveryNotSaved);
      expect(p.entitlements, isEmpty);
      expect(backend.completed, isEmpty);
    });

    test('다음 실행의 복원이 못다 한 지급을 마친다', () async {
      backend.ownedProductIds = [_rabbit];
      final p = purchases();
      await p.start();
      await settle();

      expect(p.entitlements, {'rabbit_postman'});
      expect(backend.completed, [_rabbit]);
    });
  });

  group('복원', () {
    test('실행 때 계정이 가진 것을 조용히 받는다', () async {
      backend.ownedProductIds = [_squirrel];
      final p = purchases();
      await p.start();
      await settle();

      expect(p.entitlements, {'squirrel_explorer'});
      expect(p.takeFailure(), isNull);
    });

    test('iOS 모양의 시작은 스스로 복원하지 않는다', () async {
      backend.ownedProductIds = [_squirrel];
      final p = purchases(restoreOnStart: false);
      await p.start();
      await settle();
      expect(p.entitlements, isEmpty);
    });

    test('눌러서 찾은 것이 있으면 조용하다', () async {
      final p = purchases(restoreOnStart: false);
      await p.start();
      backend.ownedProductIds = [_rabbit];
      expect(await p.restore(), isNull);
      expect(p.entitlements, {'rabbit_postman'});
    });

    test('눌렀는데 찾은 것이 없으면 그렇다고 말한다', () async {
      final p = purchases(restoreOnStart: false);
      await p.start();
      expect(await p.restore(), PurchaseFailure.nothingToRestore);
    });

    test('스토어에 닿지 못하면 그렇다고 말한다', () async {
      final p = purchases(restoreOnStart: false);
      await p.start();
      backend.failRestore = true;
      expect(await p.restore(), PurchaseFailure.storeUnavailable);
    });

    test('복원 중에 끝난 결제는 복원의 답이 되지 않는다', () async {
      final p = purchases(restoreOnStart: false);
      await p.start();
      await p.buy(_rabbit);
      final restoring = p.restore();
      backend.emit([detailsFor(_rabbit, PurchaseStatus.purchased)]);
      expect(await restoring, PurchaseFailure.nothingToRestore);
    });
  });

  group('Play가 더는 결제된 것으로 쥐지 않은 구매는', () {
    test('실행 때 거둔다', () async {
      store.saved = {'rabbit_postman'};
      backend.paidProductIds = {};
      final p = purchases();
      await p.start();

      expect(p.entitlements, isEmpty);
      expect(store.saved, isEmpty);
    });

    test('아직 결제된 것은 두고 환불된 것만 거둔다', () async {
      store.saved = {'rabbit_postman', 'squirrel_explorer'};
      backend.paidProductIds = {_squirrel};
      final p = purchases();
      await p.start();
      expect(p.entitlements, {'squirrel_explorer'});
    });

    test('환불된 번들은 광고 제거까지 거두지만 단품으로 산 팩은 남긴다', () async {
      store.saved = {
        ...StoreProductCatalog.grants[_bundle]!,
      };
      backend.paidProductIds = {_rabbit};
      final p = purchases();
      await p.start();

      expect(p.adFree, isFalse);
      expect(p.entitlements, {'rabbit_postman'});
    });

    test('스토어가 답하지 못하면 아무것도 거두지 않는다', () async {
      store.saved = {'rabbit_postman'};
      backend.paidProductIds = null;
      final p = purchases();
      await p.start();
      expect(p.entitlements, {'rabbit_postman'});
    });

    test('이번 실행에 지급된 것은 거두지 않는다', () async {
      backend
        ..ownedProductIds = [_rabbit]
        ..paidProductIds = {};
      final p = purchases();
      await p.start();
      await settle();
      expect(p.entitlements, {'rabbit_postman'});
    });
  });

  group('앞으로 돌아오면', () {
    test('앱 밖에서 받은 것을 받는다', () async {
      final p = purchases();
      await p.start();
      backend.ownedProductIds = [_squirrel];
      await p.refreshOnResume();
      await settle();
      expect(p.entitlements, {'squirrel_explorer'});
    });

    test('결제 창이 열린 동안에는 묻지 않는다', () async {
      final p = purchases();
      await p.start();
      await p.buy(_rabbit);
      backend.ownedProductIds = [_squirrel];
      await p.refreshOnResume();
      await settle();
      expect(p.entitlements, isEmpty);
    });
  });
}
