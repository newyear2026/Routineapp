import '../../application/store/pack_purchases.dart';
import '../../l10n/app_localizations.dart';

/// 구매가 끝나지 않은 이유를 사용자 말로.
String purchaseFailureMessage(AppLocalizations l10n, PurchaseFailure failure) =>
    switch (failure) {
      PurchaseFailure.storeUnavailable => l10n.purchaseStoreUnavailable,
      PurchaseFailure.purchaseRejected => l10n.purchaseRejected,
      PurchaseFailure.nothingToRestore => l10n.purchaseNothingToRestore,
      PurchaseFailure.deliveryNotSaved => l10n.purchaseNotSaved,
    };
