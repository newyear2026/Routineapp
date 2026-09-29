/// 광고 노출 상한. 숫자를 바꾸려면 여기만 고친다.
///
/// 슬롯 수와 노출 수는 다르다. 자리를 늘리는 만큼 상한을 같이 걸어야
/// 체감 광고량이 늘지 않는다 — `docs/AD_PLACEMENT.md`.
abstract final class AdPlacementCaps {
  /// 설치 직후 광고를 띄우지 않는 기간.
  ///
  /// 온보딩·알림 권한·초기 루틴 설정을 지나 앱이 습관이 되기 전까지는
  /// 어떤 자리도 뜨지 않는다.
  ///
  /// 비공개 테스트 빌드는 이 값을 0으로 덮어쓴다. 테스터의 관심은 앞쪽
  /// 며칠에 몰리므로, 48시간을 그대로 두면 상당수가 광고를 한 번도 못 본
  /// 채로 테스트가 끝난다 — 검증하려고 넣은 광고가 검증되지 않는다.
  static const Duration warmUp = Duration(hours: 48);

  /// 한 세션에 보이는 네이티브 광고 총량.
  ///
  /// Phase 2에서 Slot A와 C를 한 세션에 모두 보더라도 여기까지다.
  static const int nativeImpressionsPerSession = 2;

  /// 보상형 광고를 하루에 볼 수 있는 횟수.
  static const int rewardedPerDay = 3;

  /// Slot A를 띄우려면 «다음 일정»에 최소 몇 개가 남아 있어야 하는가.
  ///
  /// 목록이 비면 캡션 한 줄만 나오는데, 그 뒤에 광고를 붙이면 광고가
  /// 그 섹션의 본문이 된다.
  static const int minUpcomingForHomeSlot = 1;

  /// Slot C를 띄우려면 오늘 루틴이 최소 몇 개여야 하는가.
  ///
  /// 리스트가 짧으면 화면에서 광고가 차지하는 비중이 커진다.
  static const int minTodayRoutinesForProgressSlot = 4;
}
