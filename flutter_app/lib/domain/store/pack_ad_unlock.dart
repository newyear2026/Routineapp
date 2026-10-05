import 'character_pack.dart';

/// 광고로 여는 팩의 진행 — 팩마다 끝까지 본 광고 수 하나.
///
/// 수만 저장하고 «열렸는가»는 읽을 때마다 [RewardedUnlockOwnership.adsRequired]
/// 와 견준다. 필요한 수를 바꿔도 저장값을 고쳐 쓸 일이 없다.
abstract interface class PackAdUnlockStore {
  Future<Map<String, int>> loadAdViews();

  Future<void> saveAdViews(String packId, int count);
}

/// 광고를 보고 팩을 열려 할 때 일어날 수 있는 일.
enum PackAdUnlockOutcome {
  /// 필요한 만큼 봤다. 팩이 영구히 열렸고 바로 적용됐다.
  unlocked,

  /// 광고를 끝까지 봤지만 아직 더 봐야 한다. 본 수는 저장됐다.
  progressed,

  /// 광고를 도중에 닫았다. 세지 않는다.
  adNotCompleted,

  /// 광고를 불러오지 못했다 — 네트워크, 채울 광고 없음, SDK 미준비.
  adUnavailable,

  /// 광고는 봤는데 팩을 적용하지 못했다(저장 실패 등).
  failed,
}

/// 구매 판정에 광고 해금을 얹은 소유 판정.
///
/// 결제 판정([base])을 대신하지 않고 감싼다. 결제가 붙으면 [base] 자리에
/// 구매 저장소가 들어오고, 산 팩은 광고 수와 상관없이 소유다.
class RewardedUnlockOwnership implements CharacterPackOwnership {
  RewardedUnlockOwnership({
    required this.base,
    required Map<String, int> adViews,
    required this.rewardedAdsAvailable,
  }) : _adViews = Map.unmodifiable(adViews);

  /// 팩 하나를 영구히 여는 데 끝까지 봐야 하는 광고 수. 나눠 봐도 된다.
  ///
  /// 한 번이면 결제가 붙었을 때 살 이유가 사라지고, 너무 많으면 팩 하나에
  /// 광고를 몇 분씩 봐야 해 중간에 포기한다.
  static const int adsRequired = 2;

  final CharacterPackOwnership base;

  /// 이 플랫폼에서 보상형 광고를 띄울 수 있는가.
  ///
  /// false면 광고로 여는 팩을 무료로 푼다. iOS는 AdMob 앱 등록 전이라
  /// 광고를 켜지 않는데, 그렇다고 팩을 영영 잠가 두면 열 방법이 없다.
  final bool rewardedAdsAvailable;

  final Map<String, int> _adViews;

  @override
  bool owns(CharacterPack pack) {
    if (base.owns(pack)) return true;
    if (pack.availability != CharacterPackAvailability.rewardedUnlock) {
      return false;
    }
    if (!rewardedAdsAvailable) return true;
    return adViews(pack) >= adsRequired;
  }

  /// [pack]을 위해 끝까지 본 광고 수. [adsRequired]를 넘지 않는다.
  int adViews(CharacterPack pack) =>
      (_adViews[pack.id] ?? 0).clamp(0, adsRequired);

  /// 광고를 보고 [pack]을 열 수 있는가 — 광고로 여는 팩이고 아직 열리지 않았다.
  bool canWatchAd(CharacterPack pack) =>
      rewardedAdsAvailable &&
      pack.availability == CharacterPackAvailability.rewardedUnlock &&
      !owns(pack);
}
