import '../../data/local/ad_local_storage.dart';
import '../../domain/ads/ad_policy_context.dart';
import '../../domain/ads/ad_slot.dart';
import '../../domain/ads/ad_slot_decision.dart';
import '../../domain/ads/ad_slot_policy.dart';
import 'ad_config.dart';

/// 세션 상태를 들고 [AdSlotPolicy]에 물어보는 창구.
///
/// 화면은 이 서비스에만 말을 건다. 조건 판단은 정책이, 저장은 저장소가,
/// 세션 카운트는 여기가 맡는다.
///
/// 세션의 경계는 앱 프로세스다. 프로세스가 죽으면 카운트도 사라진다.
class AdPolicyService {
  AdPolicyService({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static final AdPolicyService instance = AdPolicyService();

  final DateTime Function() _clock;

  bool _startedFromNotification = false;
  int _nativeImpressions = 0;
  final Set<AdSlot> _shownSlots = <AdSlot>{};

  /// 알림이나 홈 위젯을 눌러 들어왔다고 표시한다.
  ///
  /// "지금 이걸 할 시간"이라고 불러놓고 광고를 띄우면 알림 자체를 꺼버린다.
  /// 이번 세션 동안 밀어 넣는 광고를 전부 막는다.
  void markStartedFromNotification() => _startedFromNotification = true;

  Future<AdSlotDecision> decide(
    AdSlot slot, {
    int upcomingCount = 0,
    int todayRoutineCount = 0,
    bool isPro = false,
  }) async {
    final now = _clock();
    return AdSlotPolicy.decide(
      slot,
      AdPolicyContext(
        now: now,
        firstLaunchAt: await AdLocalStorage.ensureFirstLaunchAt(now),
        warmUp: AdConfig.warmUp,
        startedFromNotification: _startedFromNotification,
        nativeImpressionsThisSession: _nativeImpressions,
        slotsShownThisSession: _shownSlots,
        rewardedShownToday: await AdLocalStorage.rewardedShownToday(now),
        upcomingCount: upcomingCount,
        todayRoutineCount: todayRoutineCount,
        isPro: isPro,
        platformSupported: AdConfig.isPlatformSupported,
      ),
    );
  }

  /// 광고를 실제로 띄운 뒤에 부른다. 요청 시점이 아니라 노출 시점이다.
  ///
  /// 요청할 때 세면 채워지지 않은 광고까지 상한을 소진해, 사용자는 아무것도
  /// 못 봤는데 «오늘은 여기까지»가 되어 버린다.
  Future<void> recordShown(AdSlot slot) async {
    _shownSlots.add(slot);
    if (slot.isUserInitiated) {
      await AdLocalStorage.recordRewardedShown(_clock());
    } else {
      _nativeImpressions++;
    }
  }

  /// 테스트용 — 세션 상태를 처음으로 되돌린다.
  void resetSession() {
    _startedFromNotification = false;
    _nativeImpressions = 0;
    _shownSlots.clear();
  }
}
