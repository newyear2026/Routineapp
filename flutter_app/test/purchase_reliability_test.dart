import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:routine_timer/application/store/pack_purchases.dart';

import 'support/fake_purchase_backend.dart';

const _grants = {
  'rabbit': {'rabbit_pack'},
  'squirrel': {'squirrel_pack'},
};

class _DelayedStore extends MemoryEntitlementStore {
  _DelayedStore([super.initial]);

  final firstSaveStarted = Completer<void>();
  final releaseFirstSave = Completer<void>();

  @override
  Future<void> save(Set<String> entitlements) async {
    if (!firstSaveStarted.isCompleted) {
      firstSaveStarted.complete();
      await releaseFirstSave.future;
    }
    await super.save(entitlements);
  }
}

class _CompletionBackend extends FakePurchaseBackend {
  final attempts = <String>[];
  bool failRabbit = true;
  Completer<void>? rabbitResponse;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    attempts.add(purchase.productID);
    if (purchase.productID == 'rabbit') {
      if (rabbitResponse != null) await rabbitResponse!.future;
      if (failRabbit) throw PlatformException(code: 'billing_disconnected');
    }
    await super.completePurchase(purchase);
  }
}

void main() {
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('연달아 도착한 구매와 복원은 앞선 저장이 느려도 모두 남는다', () async {
    final backend = FakePurchaseBackend();
    final store = _DelayedStore();
    final purchases = PackPurchases(
        backend: backend, store: store, grants: _grants, restoreOnStart: false);
    addTearDown(backend.close);
    addTearDown(purchases.dispose);
    await purchases.start();

    backend.emit([detailsFor('rabbit', PurchaseStatus.purchased)]);
    await store.firstSaveStarted.future;
    backend.emit([detailsFor('squirrel', PurchaseStatus.restored)]);
    await settle();
    store.releaseFirstSave.complete();
    await settle();

    expect(store.saved, {'rabbit_pack', 'squirrel_pack'});
    expect(purchases.entitlements, store.saved);
    expect(backend.completed, ['rabbit', 'squirrel']);
  });

  test('환불 회수 저장 중 도착한 새 구매도 덮어쓰지 않는다', () async {
    final backend = FakePurchaseBackend()..paidProductIds = {};
    final store = _DelayedStore({'rabbit_pack'});
    final purchases =
        PackPurchases(backend: backend, store: store, grants: _grants);
    addTearDown(backend.close);
    addTearDown(purchases.dispose);
    final starting = purchases.start();
    await store.firstSaveStarted.future;
    backend.emit([detailsFor('squirrel', PurchaseStatus.purchased)]);
    await settle();
    store.releaseFirstSave.complete();
    await starting;
    await settle();

    expect(store.saved, {'squirrel_pack'});
    expect(purchases.entitlements, store.saved);
  });

  testWidgets('한 상품 완료 실패에도 다른 상품을 복원하고 실패한 완료만 재시도한다', (tester) async {
    final backend = _CompletionBackend();
    final store = MemoryEntitlementStore();
    final purchases = PackPurchases(
        backend: backend, store: store, grants: _grants, restoreOnStart: false);
    addTearDown(backend.close);
    addTearDown(purchases.dispose);
    await purchases.start();
    final shown = <Set<String>>[];
    purchases.addListener(() => shown.add({...purchases.entitlements}));

    backend.emit([
      detailsFor('rabbit', PurchaseStatus.restored),
      detailsFor('squirrel', PurchaseStatus.restored),
    ]);
    await tester.pump();
    expect(store.saved, {'rabbit_pack', 'squirrel_pack'});
    expect(shown.last, store.saved);
    expect(backend.completed, ['squirrel']);
    expect(purchases.takeFailure(), isNull, reason: '지급된 팩을 구매 실패라고 안내하지 않는다');

    backend.failRabbit = false;
    await tester.pump(const Duration(seconds: 30));
    expect(backend.attempts, ['rabbit', 'squirrel', 'rabbit']);
    expect(backend.completed, ['squirrel', 'rabbit']);
    expect(store.saved, {'rabbit_pack', 'squirrel_pack'});
    await tester.pump(const Duration(minutes: 1));
    expect(backend.attempts, hasLength(3), reason: '성공한 완료는 다시 보내지 않는다');
  });

  testWidgets('완료 응답이 없어도 지급을 표시하고 다음 상품 복원을 이어 간다', (tester) async {
    final backend = _CompletionBackend()..rabbitResponse = Completer<void>();
    final store = MemoryEntitlementStore();
    final purchases = PackPurchases(
        backend: backend, store: store, grants: _grants, restoreOnStart: false);
    addTearDown(backend.close);
    addTearDown(purchases.dispose);
    await purchases.start();
    final shown = <Set<String>>[];
    purchases.addListener(() => shown.add({...purchases.entitlements}));
    backend.emit([
      detailsFor('rabbit', PurchaseStatus.restored),
      detailsFor('squirrel', PurchaseStatus.restored),
    ]);
    await tester.pump();
    expect(shown.last, {'rabbit_pack'});
    await tester.pump(const Duration(seconds: 10));
    expect(shown.last, {'rabbit_pack', 'squirrel_pack'});
    expect(backend.completed, ['squirrel']);
    backend.failRabbit = false;
    backend.rabbitResponse!.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));
    expect(purchases.entitlements, {'rabbit_pack', 'squirrel_pack'});
  });

  testWidgets('종료한 구매 컨트롤러는 완료 재시도를 계속하지 않는다', (tester) async {
    final backend = _CompletionBackend();
    final purchases = PackPurchases(
        backend: backend,
        store: MemoryEntitlementStore(),
        grants: _grants,
        restoreOnStart: false);
    addTearDown(backend.close);
    await purchases.start();
    backend.emit([detailsFor('rabbit', PurchaseStatus.purchased)]);
    await tester.pump();
    purchases.dispose();
    await tester.pump(const Duration(minutes: 1));
    expect(backend.attempts, ['rabbit']);
  });
}
