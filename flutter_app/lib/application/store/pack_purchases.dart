import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../data/store/store_product_catalog.dart';
import '../../domain/store/purchase_ownership.dart';

/// 구매가 끝나지 않은 이유 — 화면이 말로 바꿀 수 있는 모양으로.
///
/// 플러그인의 메시지는 Play Billing의 영어 문장이라 그대로 보여 주지 않는다.
/// 취소는 여기 없다. 사용자가 뜻한 일이지 알릴 실패가 아니다.
enum PurchaseFailure {
  /// 스토어에 닿을 수 없다 — Play 서비스 없음, 구매가 막힌 계정, 결제가
  /// 없는 빌드, 아직 가격을 받지 못한 상품.
  storeUnavailable,

  /// 스토어가 답했지만 결제 자체가 오류로 돌아왔다.
  purchaseRejected,

  /// 복원을 돌렸는데 돌려줄 것이 없었다.
  nothingToRestore,

  /// 스토어는 지급했는데 저장이 되지 않았다.
  ///
  /// 잃은 것은 아니다. 구매를 일부러 완료하지 않고 두므로 다음 실행에 Play가
  /// 다시 보내고 그때 지급된다. 그래도 말하지 않으면 방금 돈을 낸 사람이
  /// 여전히 파는 중인 팩을 보게 된다.
  deliveryNotSaved,
}

/// 이 설치에서 스토어가 지금 할 수 있는 일.
enum StoreReadiness { checking, ready, unavailable }

/// `in_app_purchase` 플러그인과의 경계.
///
/// 스토어 없이 구매 논리를 시험하려고 둔다. 모든 메서드는 플러그인이 이미
/// 제공하는 것이고, 진짜 스토어와 말하는 구현은 [PluginPurchaseBackend]뿐이다.
abstract interface class PurchaseBackend {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);
  Future<void> buyNonConsumable(ProductDetails product);
  Future<void> restorePurchases();
  Future<void> completePurchase(PurchaseDetails purchase);

  /// 이 스토어 계정이 지금 결제된 것으로 쥔 상품. 확실히 말할 수 없으면 null.
  ///
  /// 실패와 이런 조회가 없는 플랫폼은 모두 null이어야 한다. 빈 집합은 «아무
  /// 것도 없다»는 주장이고, 그 주장대로 산 것을 거둬들인다.
  Future<Set<String>?> queryPaidProductIds();
}

/// 결제가 없는 플랫폼. 스토어가 없다고만 답한다.
///
/// LOOPET은 Android에만 출시한다. iOS·웹·테스트에서 플러그인을 부르면
/// 채널이 없어 예외가 나므로, 부르지 않는 쪽을 둔다.
final class UnavailablePurchaseBackend implements PurchaseBackend {
  const UnavailablePurchaseBackend();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(productDetails: const [], notFoundIDs: [...ids]);

  @override
  Future<void> buyNonConsumable(ProductDetails product) async =>
      throw StateError('no store on this platform');

  @override
  Future<void> restorePurchases() async =>
      throw StateError('no store on this platform');

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  Future<Set<String>?> queryPaidProductIds() async => null;
}

/// 플러그인 싱글턴으로 닿는 진짜 스토어.
final class PluginPurchaseBackend implements PurchaseBackend {
  PluginPurchaseBackend([InAppPurchase? plugin])
      : _plugin = plugin ?? InAppPurchase.instance;

  final InAppPurchase _plugin;

  /// Play의 대기 중 구매를 «대기»라고 부르는 스트림.
  ///
  /// Android 플러그인은 복원으로 돌아온 것을 모두 restored로 표시한다. 편의점
  /// 현금 결제처럼 아직 돈이 들어오지 않은 구매도 마찬가지라, 그대로 넘기면
  /// 다음 실행에 결제되지 않은 팩이 열린다.
  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _plugin.purchaseStream.map(
        (purchases) => [
          for (final purchase in purchases)
            if (purchase is GooglePlayPurchaseDetails &&
                purchase.status == PurchaseStatus.restored &&
                purchase.billingClientPurchase.purchaseState ==
                    PurchaseStateWrapper.pending)
              purchase..status = PurchaseStatus.pending
            else
              purchase,
        ],
      );

  @override
  Future<bool> isAvailable() => _plugin.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) =>
      _plugin.queryProductDetails(identifiers);

  @override
  Future<void> buyNonConsumable(ProductDetails product) => _plugin
      .buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));

  @override
  Future<void> restorePurchases() => _plugin.restorePurchases();

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _plugin.completePurchase(purchase);

  /// Play Billing에 직접 묻는다. 구매마다 실제 상태로 답한다.
  @override
  Future<Set<String>?> queryPaidProductIds() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    final response = await _plugin
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
        .queryPastPurchases();
    if (response.error != null) return null;
    return {
      for (final purchase in response.pastPurchases)
        if (purchase.status == PurchaseStatus.purchased) purchase.productID,
    };
  }
}

/// LOOPET 쪽 스토어 — 보여 줄 가격, 시작할 구매, 지급된 권리.
///
/// 파는 것은 모두 비소모성이다. 그래서 자체 계정 없이도 재설치가 복구된다 —
/// Play가 사용자의 스토어 계정에 구매를 남기고, 요청하면 다시 보내 준다.
///
/// 권리 집합이 바뀌면 알린다. `RoutineAppController`가 듣고 팩 소유 판정을
/// 다시 만든다.
class PackPurchases extends ChangeNotifier {
  PackPurchases({
    required PurchaseBackend backend,
    required EntitlementStore store,
    Map<String, Set<String>>? grants,
    this.restoreOnStart = true,
    this.restoreGrace = const Duration(seconds: 6),
    this.checkoutTimeout = const Duration(minutes: 3),
  })  : _backend = backend,
        _store = store,
        _grants = grants ?? StoreProductCatalog.grants;

  final PurchaseBackend _backend;
  final EntitlementStore _store;

  /// 상품 ID → 지급할 권리. 테스트가 제 목록을 넘긴다.
  final Map<String, Set<String>> _grants;

  /// [start]가 스스로 지난 구매를 다시 받아 오는가.
  ///
  /// Android에서는 Play 계정에 조용히 묻는 일이라 참이다. iOS에서는 거짓이어야
  /// 한다 — StoreKit 복원은 로그인 창을 띄울 수 있고, 실행하자마자 그 창이
  /// 뜨면 앱이 로그인을 요구하는 것처럼 읽힌다.
  final bool restoreOnStart;

  /// [restore]가 스토어의 답을 기다리는 시간.
  ///
  /// `restorePurchases`는 요청을 보내자마자 돌아오고, 찾은 것은 그 뒤에 구매
  /// 스트림으로 온다. 돌아오자마자 결과를 읽으면 늘 «없음»이라, 잘 된 복원이
  /// 실패했다고 말하게 된다. 느린 망에는 충분하고, 정말 빈 계정을 오래 세워
  /// 두지는 않을 만큼.
  final Duration restoreGrace;

  /// 버튼이 «결제 중»이라고 말할 수 있는 최대 시간.
  ///
  /// 결제 창의 평범한 끝은 모두 스트림으로 오지만, 모든 끝이 평범하지는 않다.
  /// 쓸어 닫은 창이나 뒤에서 죽은 프로세스는 아무것도 보내지 않을 수 있다.
  /// 기한이 없으면 앱을 다시 켤 때까지 구매 중으로 남고, 그걸 풀 버튼이 바로
  /// 비활성된 그 버튼이다. Play가 돈을 받아 쥐고 있는 대기 구매는 따로 세고
  /// 기한 없이 기다린다.
  final Duration checkoutTimeout;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Future<void> _purchaseWork = Future.value();
  final Map<String, PurchaseDetails> _pendingCompletions = {};
  Timer? _completionRetryTimer;
  bool _disposed = false;
  final Map<String, ProductDetails> _products = {};
  final Map<String, Timer> _checkingOut = {};

  /// Play가 돈을 받았지만 아직 확정하지 않은 상품 — 편의점 현금 결제,
  /// 보호자 승인 대기. 기한이 없다.
  final Set<String> _pending = {};
  Set<String> _entitlements = const {};
  StoreReadiness _readiness = StoreReadiness.checking;
  PurchaseFailure? _pendingFailure;
  bool _restoreGrantedSomething = false;
  bool _refreshing = false;

  /// 이번 실행에 스토어가 지급한 권리. 환불 회수가 건드리면 안 된다.
  ///
  /// Play의 결제 목록은 한 번 읽는데, 그 답이 오는 사이에 결제가 끝날 수
  /// 있다. 이게 없으면 같은 몇 초에 끝난 구매가 지급되자마자 회수된다.
  final Set<String> _deliveredThisRun = {};
  Completer<void>? _awaitingRestore;

  StoreReadiness get readiness => _readiness;

  /// 지금 가진 권리 — 팩 ID와 [StoreProductCatalog.adFree].
  Set<String> get entitlements => _entitlements;

  /// 네이티브 광고를 끄는가.
  bool get adFree => _entitlements.contains(StoreProductCatalog.adFree);

  /// 스토어가 [productId]를 처리하는 중인가.
  bool isBuying(String productId) =>
      _checkingOut.containsKey(productId) || _pending.contains(productId);

  /// [productId]가 Play에서 결제 확인을 기다리는 중인가.
  bool isPending(String productId) => _pending.contains(productId);

  /// 진행 중인 구매가 있는가. 느린 스토어에서 두 번째 결제를 열지 않게.
  bool get isBusy => _checkingOut.isNotEmpty || _pending.isNotEmpty;

  /// 스토어가 알려 준 현지 가격. 아직 모르면 null.
  String? priceFor(String productId) => _products[productId]?.price;

  /// [productId]가 지급하는 것을 모두 이미 가졌는가.
  bool ownsProduct(String productId) =>
      (_grants[productId] ?? {productId}).every(_entitlements.contains);

  /// 보여 줄 실패. 읽으면 지워진다 — 다른 이유로 다시 그려도 같은 오류를
  /// 두 번 말하지 않게.
  ///
  /// 스트림이 스스로 올리는 실패만 담는다. 복원은 부른 쪽에 직접 답한다.
  PurchaseFailure? takeFailure() {
    final failure = _pendingFailure;
    _pendingFailure = null;
    return failure;
  }

  /// 저장된 권리를 읽고, 스토어에 붙고, 가격을 받고, 지난 구매를 다시 받는다.
  ///
  /// 던지지 않는다. 스토어에 닿지 못하면 가격 없이 팩을 보여 줄 뿐이다.
  Future<void> start() async {
    try {
      final saved = await _store.load();
      // 같은 내용이면 바꾸지 않는다. 새 집합은 곧 «권리가 바뀌었다»는 신호라,
      // 받은 쪽이 팩 화면을 통째로 다시 그린다.
      if (!setEquals(saved, _entitlements)) {
        _entitlements = Set.unmodifiable(saved);
      }
    } on Object catch (error) {
      debugPrint('LOOPET: 구매 장부를 읽지 못했다: $error');
    }
    notifyListeners();
    _subscription ??= _backend.purchaseStream.listen(
      (purchases) =>
          unawaited(_enqueuePurchaseWork(() => _handlePurchases(purchases))),
      onError: (Object _) => _report(PurchaseFailure.purchaseRejected),
    );
    bool available;
    try {
      available = await _backend.isAvailable();
    } on Object {
      available = false;
    }
    if (!available) {
      _readiness = StoreReadiness.unavailable;
      notifyListeners();
      return;
    }
    _readiness = StoreReadiness.ready;
    await _loadPrices();
    if (restoreOnStart) {
      // 실행 때의 «돌려줄 것 없음»은 알리지 않는다. 사용자가 묻지 않았고,
      // 대부분의 실행은 정상적으로 아무것도 돌려받지 않는다.
      try {
        await _backend.restorePurchases();
      } on Object {
        // 실행 때의 복원 실패는 화면에 바뀌는 것이 없다. 설정의 «구매 복원»이
        // 스스로 결과를 말하는 자리다.
      }
      await _takeBackWhatIsNoLongerPaid();
    }
    notifyListeners();
  }

  /// 앱이 앞으로 돌아올 때 지난 구매를 다시 받는다.
  ///
  /// 앱이 뒤에 있는 사이 Play 스토어에서 쓴 프로모션 코드 같은 것을 잡는다.
  /// Play는 떠 있는 앱에 알리지 않으므로, 묻지 않으면 다음 냉시작까지 — 앱을
  /// 살려 두는 폰에서는 며칠까지 — 기다리게 된다. 결제 창도 앱을 뒤로 보내는
  /// 일이라, 결제 중에는 묻지 않는다.
  Future<void> refreshOnResume() async {
    if (!restoreOnStart ||
        _readiness != StoreReadiness.ready ||
        _checkingOut.isNotEmpty ||
        _refreshing) {
      return;
    }
    _refreshing = true;
    try {
      await _backend.restorePurchases();
    } on Object {
      // 사용자가 요청한 일이 실패한 것이 아니다. 다음 복귀 때 다시 묻는다.
    } finally {
      _refreshing = false;
    }
  }

  /// 스토어 계정이 더는 결제된 것으로 쥐지 않은 권리를 거둔다.
  ///
  /// 환불, 지불 거절, 기한이 지난 현금 결제는 여기서 모두 같아 보인다 — Play
  /// 목록에서 상품이 사라진다. 이 일은 구매 스트림으로 오지 않으므로 묻지
  /// 않으면 이 폰에서 영영 열려 있다.
  ///
  /// 되돌릴 수 있다. Play 목록은 계정마다라, 다른 Play 계정의 폰에서는 여기서도
  /// 거둬지지만 결제한 계정이 돌아오는 순간 실행 복원이 다시 준다. 조용히
  /// 한다 — 환불을 요청한 사람은 이유를 알고, 메시지는 앱이 따지는 것이 된다.
  Future<void> _takeBackWhatIsNoLongerPaid() async {
    Set<String>? paid;
    try {
      paid = await _backend.queryPaidProductIds();
    } on Object {
      paid = null;
    }
    // 답이 없는 것은 빈 답이 아니다. 조회 실패에 회수하면 오프라인으로 켤
    // 때마다 결제한 사용자가 빈손이 된다.
    if (paid == null) return;
    // 지급과 회수 모두 같은 큐에서 최신 장부를 읽고 저장한다.
    // 회수 저장을 기다리는 사이 들어온 구매도 덮어쓰지 않는다.
    await _enqueuePurchaseWork(() => _removeUnpaidEntitlements(paid!));
  }

  Future<void> _removeUnpaidEntitlements(Set<String> paid) async {
    final stillPaidFor = {
      for (final productId in paid) ..._deliveredBy(productId),
    };
    final revoked = {
      for (final productId in _grants.keys)
        if (!paid.contains(productId)) ..._deliveredBy(productId),
    }
      ..removeAll(stillPaidFor)
      ..removeAll(_deliveredThisRun);
    revoked.retainWhere(_entitlements.contains);
    if (revoked.isEmpty) return;
    final kept = _entitlements.difference(revoked);
    try {
      await _store.save(kept);
      _entitlements = Set.unmodifiable(kept);
    } on Object catch (error) {
      // 다음 실행이 다시 묻고 같은 답을 받는다.
      debugPrint('LOOPET: $revoked 회수를 저장하지 못했다: $error');
    }
  }

  Set<String> _deliveredBy(String productId) =>
      _grants[productId] ?? {productId};

  Future<void> _loadPrices() async {
    final ids = _grants.keys.toSet();
    if (ids.isEmpty) return;
    try {
      final response = await _backend.queryProductDetails(ids);
      _products
        ..clear()
        ..addEntries(
          response.productDetails.map(
            (product) => MapEntry(product.id, product),
          ),
        );
      // 오류로 보이지 않는다. 빌드의 상품 목록이 Play Console 등록보다 앞선
      // 모습이고, 등록이 따라올 때까지 그 상품은 가격 없이 보인다.
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('LOOPET: 스토어에 등록되지 않은 상품 ${response.notFoundIDs}');
      }
    } on Object catch (error) {
      debugPrint('LOOPET: 가격을 불러오지 못했다: $error');
    }
  }

  /// [productId]의 구매를 시작한다.
  ///
  /// 이미 다 가졌거나 같은 상품의 결제 창이 열려 있으면 아무것도 하지 않는다.
  /// 느린 스토어에서 두 번째 탭이 두 번째 결제를 열면 안 된다.
  Future<void> buy(String productId) async {
    if (ownsProduct(productId) || isBuying(productId)) return;
    final product = _products[productId];
    if (product == null) {
      _report(PurchaseFailure.storeUnavailable);
      return;
    }
    _checkingOut[productId] = Timer(checkoutTimeout, () {
      _checkingOut.remove(productId);
      notifyListeners();
    });
    notifyListeners();
    try {
      await _backend.buyNonConsumable(product);
    } on Object {
      _endCheckout(productId);
      _report(PurchaseFailure.purchaseRejected);
    }
  }

  void _endCheckout(String productId) =>
      _checkingOut.remove(productId)?.cancel();

  void _endUnsuccessfulPurchase(String productId) {
    if (productId.isEmpty) {
      // Android는 구매 목록이 없는 취소·오류를 빈 상품 ID로 보낸다.
      // 열린 결제 창의 상태만 풀고 Play의 실제 승인 대기 구매는 유지한다.
      for (final timer in _checkingOut.values) {
        timer.cancel();
      }
      _checkingOut.clear();
      return;
    }
    _endCheckout(productId);
    _pending.remove(productId);
  }

  /// 이 스토어 계정이 이미 가진 것을 다시 받고, 결과를 답한다.
  ///
  /// 결과를 [takeFailure]에 두지 않고 돌려준다. 물어본 행이 답해야 한다.
  /// null이면 무언가 돌아왔다. 실행 때 복원과 달리 빈 결과도 말한다 — 사용자가
  /// 눌렀는데 아무 답도 없는 버튼은 고장 난 것으로 읽힌다.
  Future<PurchaseFailure?> restore() async {
    _restoreGrantedSomething = false;
    // 요청 전에 연다. 복원 결과가 `restorePurchases`가 돌아오는 사이에 스트림에
    // 닿을 수 있고, 그 뒤에 열면 지급과 경주하게 된다 — 지면 구매가 가득한
    // 계정이 기다리기만 하다 «없음»을 듣는다.
    final waiting = _awaitingRestore = Completer<void>();
    try {
      await _backend.restorePurchases();
    } on Object {
      _awaitingRestore = null;
      return PurchaseFailure.storeUnavailable;
    }
    // 요청이 아니라 결과를 기다린다. 첫 지급이 대기를 일찍 끝내므로 구매가
    // 있는 계정은 스토어만큼 빨리 답하고, 빈 계정만 유예 시간을 다 쓴다.
    await Future.any([waiting.future, Future<void>.delayed(restoreGrace)]);
    _awaitingRestore = null;
    return _restoreGrantedSomething ? null : PurchaseFailure.nothingToRestore;
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (_disposed) return;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Play가 돈을 받고 아직 확정하지 않았다. 팩은 잠긴 채로, 버튼은 지급한
          // 척하지 않고 그렇다고 말한다. Play가 걸리는 만큼 기다린다.
          _endCheckout(purchase.productID);
          _pending.add(purchase.productID);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _endCheckout(purchase.productID);
          _pending.remove(purchase.productID);
          final delivered = await _grant(
            purchase.productID,
            fromRestore: purchase.status == PurchaseStatus.restored,
          );
          if (!delivered) {
            // 일부러 완료하지 않는다. 스토어가 다시 보내고 다음 실행이 이번에
            // 못 쓴 것을 쓴다. 그리고 그 사실을 말한다.
            _pendingFailure = PurchaseFailure.deliveryNotSaved;
            continue;
          }
        case PurchaseStatus.error:
          _endUnsuccessfulPurchase(purchase.productID);
          _pendingFailure = PurchaseFailure.purchaseRejected;
        case PurchaseStatus.canceled:
          // 사용자가 물러났다. 답이지 잘못이 아니고, 무언가 말하면 취소 버튼을
          // 누른 것을 나무라는 셈이다.
          _endUnsuccessfulPurchase(purchase.productID);
      }
      // 지급된 팩은 완료 응답이 늦거나 실패해도 바로 화면에 반영한다.
      notifyListeners();
      if (purchase.pendingCompletePurchase &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored)) {
        // 반드시 지급 뒤에. 먼저 완료하고 지급에 실패하면 스토어는 준 줄 알고
        // 사용자는 빈손이다. 이 순서면 최악이 다음 실행에 다시 지급되는
        // 것뿐이고, 같은 권리를 두 번 주는 것은 아무 일도 아니다.
        await _completePurchase(purchase);
      }
    }
    notifyListeners();
  }

  /// Stream.listen은 async 콜백의 종료를 기다리지 않는다. 저장까지 한 작업으로
  /// 묶어야 연속 도착한 구매·복원 결과가 서로의 권리를 덮어쓰지 않는다.
  Future<void> _enqueuePurchaseWork(Future<void> Function() work) {
    _purchaseWork = _purchaseWork.then((_) async {
      if (!_disposed) await work();
    }).catchError((Object error, StackTrace stack) {
      debugPrint('LOOPET: 구매 처리 실패: $error\n$stack');
      if (!_disposed) _report(PurchaseFailure.purchaseRejected);
    });
    return _purchaseWork;
  }

  Future<void> _completePurchase(PurchaseDetails purchase) async {
    try {
      await _backend.completePurchase(purchase).timeout(
            const Duration(seconds: 10),
          );
      _pendingCompletions.remove(purchase.productID);
    } on Object catch (error) {
      // 지급은 끝났다. 이 상품의 완료 실패로 나머지 복원을 중단하거나
      // 이미 산 팩을 다시 잠그지 않는다. 완료 호출만 별도로 재시도한다.
      _pendingCompletions[purchase.productID] = purchase;
      debugPrint('LOOPET: ${purchase.productID} 구매 완료 재시도 예정: $error');
    }
    _scheduleCompletionRetry();
  }

  void _scheduleCompletionRetry() {
    if (_disposed || _pendingCompletions.isEmpty) {
      _completionRetryTimer?.cancel();
      _completionRetryTimer = null;
      return;
    }
    _completionRetryTimer ??= Timer(const Duration(seconds: 30), () {
      _completionRetryTimer = null;
      unawaited(_enqueuePurchaseWork(() async {
        for (final purchase in _pendingCompletions.values.toList()) {
          if (_disposed) return;
          await _completePurchase(purchase);
        }
      }));
    });
  }

  /// 권리를 장부에 쓴다. 쓰기가 됐는지 답한다.
  ///
  /// 모르는 상품 ID는 그대로 적는다. 이 빌드가 더는 팔지 않는 상품의 구매도
  /// 저장값에 남아, 그 상품을 다시 다루는 빌드가 찾을 수 있다.
  ///
  /// 복원에서 온 지급만 [restore]에 답한다. 복원을 기다리는 사이 끝난 결제가
  /// 빈 계정의 복원을 «돌아왔다»로 만들면 안 된다.
  Future<bool> _grant(String productId, {required bool fromRestore}) async {
    final ids = _deliveredBy(productId);
    _deliveredThisRun.addAll(ids);
    final next = {..._entitlements, ...ids};
    try {
      await _store.save(next);
    } on Object catch (error) {
      debugPrint('LOOPET: $productId 구매를 저장하지 못했다: $error');
      return false;
    }
    _entitlements = Set.unmodifiable(next);
    if (fromRestore) {
      _restoreGrantedSomething = true;
      if (_awaitingRestore?.isCompleted == false) _awaitingRestore!.complete();
    }
    return true;
  }

  void _report(PurchaseFailure failure) {
    _pendingFailure = failure;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _completionRetryTimer?.cancel();
    unawaited(_subscription?.cancel());
    _subscription = null;
    for (final timer in _checkingOut.values) {
      timer.cancel();
    }
    _checkingOut.clear();
    super.dispose();
  }
}
