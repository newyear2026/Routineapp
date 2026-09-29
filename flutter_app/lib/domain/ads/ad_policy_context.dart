import 'ad_slot.dart';

/// [AdSlotPolicy]가 판정에 쓰는 입력 일체.
///
/// 판정에 필요한 값을 전부 여기 모아 넘긴다. 정책이 저장소나 시계를 직접
/// 만지면 순수 함수가 아니게 되고, 그러면 상한 하나를 확인하는 데 위젯
/// 테스트를 띄워야 한다.
class AdPolicyContext {
  const AdPolicyContext({
    required this.now,
    required this.firstLaunchAt,
    required this.warmUp,
    required this.startedFromNotification,
    required this.nativeImpressionsThisSession,
    required this.slotsShownThisSession,
    required this.rewardedShownToday,
    this.upcomingCount = 0,
    this.todayRoutineCount = 0,
    this.isPro = false,
    this.platformSupported = true,
  });

  final DateTime now;

  /// 앱을 처음 실행한 시각. 아직 기록이 없으면 null — 이번이 첫 실행이다.
  final DateTime? firstLaunchAt;

  /// 워밍업 길이. 빌드로 주입해 비공개 테스트에서는 0으로 만든다.
  final Duration warmUp;

  /// 이번 세션이 알림 또는 홈 위젯을 눌러 시작됐는가.
  final bool startedFromNotification;

  final int nativeImpressionsThisSession;

  final Set<AdSlot> slotsShownThisSession;

  final int rewardedShownToday;

  /// 홈 «다음 일정»에 남은 개수 — Slot A 조건.
  final int upcomingCount;

  /// 오늘 루틴 총 개수 — Slot C 조건.
  final int todayRoutineCount;

  /// Phase 3에서 결제 상태가 들어온다. 그전까지는 항상 false다.
  final bool isPro;

  /// 이 플랫폼에서 광고를 켤 수 있는가. iOS AdMob 앱 등록 전에는 false다.
  final bool platformSupported;
}
