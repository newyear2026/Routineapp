import 'character_pack.dart';

/// 광고를 보고 받은 팩 체험 — 팩마다 끝나는 시각 하나.
///
/// 끝나는 시각만 저장하고 «지금 쓸 수 있는가»는 읽을 때마다 판정한다.
/// 만료를 지우는 작업이 따로 돌지 않아도, 시각이 지나면 `CharacterPackCatalog.resolve`
/// 가 기본 팩으로 내려 준다. 다시 광고를 보면 저장된 선택값이 그대로 살아난다.
abstract interface class PackTrialStore {
  Future<Map<String, DateTime>> loadTrialEnds();

  Future<void> saveTrialEnd(String packId, DateTime endsAt);
}

/// 광고를 보고 체험을 시작하려 할 때 일어날 수 있는 일.
enum PackTrialOutcome {
  /// 광고를 끝까지 봤고 팩이 적용됐다.
  started,

  /// 광고를 도중에 닫았다. 보상은 없다.
  adNotCompleted,

  /// 오늘 볼 수 있는 보상형 광고를 다 봤다.
  dailyLimitReached,

  /// 광고를 불러오지 못했다 — 네트워크, 채울 광고 없음, SDK 미준비.
  adUnavailable,

  /// 광고는 봤는데 팩을 적용하지 못했다(저장 실패 등).
  failed,
}

/// 구매 판정에 광고 체험을 얹은 소유 판정.
///
/// 결제 판정([base])을 대신하지 않고 감싼다. 결제가 붙으면 [base] 자리에
/// 구매 저장소가 들어오고, 산 팩은 체험과 상관없이 계속 소유다.
class RewardedTrialOwnership implements CharacterPackOwnership {
  RewardedTrialOwnership({
    required this.base,
    required Map<String, DateTime> trialEnds,
    required this.rewardedAdsAvailable,
    required DateTime Function() now,
  })  : _trialEnds = Map.unmodifiable(trialEnds),
        _now = now;

  /// 광고 한 번으로 쓸 수 있는 시간.
  ///
  /// «오늘 자정까지»로 두면 밤 11시 50분에 본 광고가 10분짜리가 된다.
  /// 본 시각부터 24시간이면 언제 보든 같은 값을 받는다.
  static const Duration trialLength = Duration(hours: 24);

  final CharacterPackOwnership base;

  /// 이 플랫폼에서 보상형 광고를 띄울 수 있는가.
  ///
  /// false면 광고로 여는 팩을 무료로 푼다. iOS는 AdMob 앱 등록 전이라
  /// 광고를 켜지 않는데, 그렇다고 팩을 영영 잠가 두면 열 방법이 없다.
  final bool rewardedAdsAvailable;

  final Map<String, DateTime> _trialEnds;
  final DateTime Function() _now;

  @override
  bool owns(CharacterPack pack) {
    if (base.owns(pack)) return true;
    if (pack.availability != CharacterPackAvailability.rewardedTrial) {
      return false;
    }
    if (!rewardedAdsAvailable) return true;
    return trialEndsAt(pack) != null;
  }

  /// 지금 체험 중이면 끝나는 시각, 아니면 null.
  ///
  /// 이미 가진 팩(산 팩 · 광고 없는 플랫폼의 무료 팩)은 체험이 아니므로 null이다.
  DateTime? trialEndsAt(CharacterPack pack) {
    if (base.owns(pack) || !rewardedAdsAvailable) return null;
    final end = _trialEnds[pack.id];
    if (end == null || !_now().isBefore(end)) return null;
    return end;
  }

  /// 광고를 보고 체험을 시작할 수 있는 팩인가.
  bool canStartTrial(CharacterPack pack) =>
      rewardedAdsAvailable &&
      pack.availability == CharacterPackAvailability.rewardedTrial &&
      !base.owns(pack);

  /// 이미 끝난 체험이 남아 있는가 — 판정 객체를 새로 만들 때를 가린다.
  bool hasExpiredEntries() {
    final now = _now();
    return _trialEnds.values.any((end) => !now.isBefore(end));
  }
}
