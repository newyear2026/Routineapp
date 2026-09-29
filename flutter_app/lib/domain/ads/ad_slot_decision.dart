/// 광고를 띄우지 않기로 한 이유.
///
/// 판정 결과를 bool 하나로 돌려주면 «왜 안 뜨지»를 추적할 수 없다.
/// 광고가 안 뜨는 건 대부분 버그가 아니라 상한이 걸린 것인데, 이유가
/// 없으면 그 둘을 구별하는 데 매번 시간이 든다.
enum AdDenialReason {
  /// 이 플랫폼에는 아직 광고를 켤 수 없다.
  ///
  /// iOS는 AdMob에 앱을 따로 등록해야 App ID가 나온다. 그 값 없이
  /// SDK를 초기화하면 실행 즉시 죽으므로, 등록 전까지 iOS는 광고를 끈다.
  platformNotSupported,

  /// 아직 켜지 않은 자리 (Phase 2 예정).
  slotNotEnabled,

  /// 설치 직후 워밍업 기간.
  warmUp,

  /// 알림·홈 위젯으로 들어온 세션.
  ///
  /// "지금 이걸 할 시간"이라고 불러놓고 광고를 띄우면 알림 자체를 꺼버린다.
  notificationEntry,

  /// 이번 세션의 네이티브 노출 상한을 채웠다.
  sessionCap,

  /// 이번 세션에 이 자리를 이미 띄웠다.
  ///
  /// 스크롤을 오갈 때마다 소재가 바뀌면 화면이 불안해진다.
  slotAlreadyShown,

  /// 오늘 보상형 광고 횟수를 채웠다.
  dailyRewardCap,

  /// 자리별 조건이 안 맞는다 (목록이 비었거나 너무 짧다).
  slotCondition,

  /// Pro 구매자 — Phase 3.
  proUser,
}

/// [AdSlotPolicy]의 판정 결과.
class AdSlotDecision {
  const AdSlotDecision._(this.reason);

  const AdSlotDecision.allow() : reason = null;

  const AdSlotDecision.deny(AdDenialReason reason) : this._(reason);

  /// 띄우기로 했으면 null.
  final AdDenialReason? reason;

  bool get isAllowed => reason == null;

  @override
  String toString() =>
      isAllowed ? 'AdSlotDecision.allow' : 'AdSlotDecision.deny($reason)';
}
