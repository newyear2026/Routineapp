/// 앱이 광고를 붙이는 자리. 자리는 여기 열거된 것이 전부다.
///
/// 새 자리를 늘리려면 이 enum에 추가하고 `docs/AD_PLACEMENT.md`의
/// «넣지 않는 자리»와 충돌하지 않는지부터 확인한다. 화면이 임의로
/// 광고를 그리기 시작하면 상한을 걸 곳이 사라진다.
enum AdSlot {
  /// Slot A — 홈 «다음 일정» 목록 마지막 카드 뒤. 네이티브.
  ///
  /// 포커스 스트립·원형 시간표·액션 바는 정보 우선순위 1~4위라 광고가
  /// 들어가지 않는다 (`PROJECT_RULES.md` 9장).
  homeUpcoming(isUserInitiated: false, enabled: true),

  /// Slot C — 진행 탭 «예정» 그룹 바로 앞. 네이티브.
  ///
  /// 자리는 확정했으나 Phase 2까지 끄고 간다. Slot A와 같은 형식이라
  /// 둘을 같이 켜면 리텐션이 떨어져도 어느 쪽 탓인지 가를 수 없다.
  progressBeforeUpcoming(isUserInitiated: false, enabled: false),

  /// Slot B — 캐릭터 팩 상세, 광고로 여는 팩의 «광고 보고 하루 써보기»를
  /// 눌렀을 때. 보상형.
  ///
  /// 사용자가 먼저 누르는 교환이라 강제 노출이 아니다.
  packTrialReward(isUserInitiated: true, enabled: true);

  const AdSlot({required this.isUserInitiated, required this.enabled});

  /// 사용자가 직접 눌러서 시작하는 자리인가.
  ///
  /// 밀어 넣는 광고와 사용자가 당긴 광고는 상한을 다르게 적용한다.
  /// 세션 상한과 «알림 진입 세션» 금지는 밀어 넣는 쪽에만 건다.
  final bool isUserInitiated;

  /// 지금 단계에서 실제로 켜는 자리인가. Phase 2에 켤 자리는 false다.
  final bool enabled;
}
