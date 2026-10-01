import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:routine_timer/application/store/pack_purchases.dart';
import 'package:routine_timer/domain/store/purchase_ownership.dart';

/// 테스트가 정한 목록으로 답하는 스토어. Play Billing 없이 구매 논리를 돌린다.
class FakePurchaseBackend implements PurchaseBackend {
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();

  bool available = true;
  bool failBuy = false;
  bool failRestore = false;
  List<ProductDetails> catalogue = [];

  /// 복원이 다시 보내는 상품.
  List<String> ownedProductIds = [];

  /// Play가 결제된 것으로 답하는 상품. null이면 말할 수 없는 스토어.
  Set<String>? paidProductIds;

  final List<String> bought = [];
  final List<String> completed = [];

  /// completePurchase마다 불린다. 그 순간 앱이 이미 무엇을 아는지 본다.
  void Function(PurchaseDetails)? onComplete;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(
        productDetails: [
          for (final product in catalogue)
            if (ids.contains(product.id)) product,
        ],
        notFoundIDs: const [],
      );

  @override
  Future<void> buyNonConsumable(ProductDetails product) async {
    if (failBuy) throw StateError('store refused');
    bought.add(product.id);
  }

  @override
  Future<void> restorePurchases() async {
    if (failRestore) throw StateError('store unreachable');
    if (ownedProductIds.isEmpty) return;
    emit([
      for (final id in ownedProductIds) detailsFor(id, PurchaseStatus.restored),
    ]);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase.productID);
    onComplete?.call(purchase);
  }

  @override
  Future<Set<String>?> queryPaidProductIds() async => paidProductIds;

  void emit(List<PurchaseDetails> purchases) => _controller.add(purchases);

  Future<void> close() => _controller.close();
}

/// 메모리에 두는 구매 장부. [failSave]면 쓰기를 거절한다.
class MemoryEntitlementStore implements EntitlementStore {
  MemoryEntitlementStore([Set<String>? initial]) : saved = {...?initial};

  Set<String> saved;
  bool failSave = false;

  @override
  Future<Set<String>> load() async => {...saved};

  @override
  Future<void> save(Set<String> entitlements) async {
    if (failSave) throw StateError('disk full');
    saved = {...entitlements};
  }
}

PurchaseDetails detailsFor(
  String productId,
  PurchaseStatus status, {
  bool needsCompleting = true,
}) =>
    PurchaseDetails(
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: '',
        source: 'test',
      ),
      transactionDate: null,
      status: status,
    )..pendingCompletePurchase = needsCompleting;

ProductDetails productFor(String id, String price) => ProductDetails(
      id: id,
      title: id,
      description: id,
      price: price,
      rawPrice: 39,
      currencyCode: 'MXN',
    );
