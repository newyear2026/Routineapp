import '../../domain/models/routine_log_status.dart';

/// 홈 첫 카드가 그리는 상태. docs/UI_STANDARDS.md «Home 첫 카드» 표와 1:1이다.
///
/// 버튼은 [showsSlotActions]인 상태에서만 보인다. 누를 수 없는 버튼을
/// 흐리게 남겨 두면 예정 루틴에 «완료»가 떠 있는 것처럼 읽힌다.
enum HomeFocusState {
  /// 지금 시간 안의 루틴이고 아직 기록이 없다.
  active,

  /// 지금 시간 안의 루틴을 미뤘고, 다시 알릴 시각이 아직 오지 않았다.
  snoozed,

  /// 지금 시간 안의 루틴을 완료했다. 시간은 아직 남았다.
  completed,

  /// 지금 시간 안의 루틴을 건너뛰었다.
  skipped,

  /// 지금 시간 안의 루틴이 없고 오늘 다음 루틴이 있다.
  upcoming,

  /// 오늘 루틴은 있지만 모두 시간이 지났다.
  dayDone,

  /// 오늘 루틴이 하나도 없다.
  empty;

  bool get showsSlotActions => this == active || this == snoozed;

  /// 지금 슬롯의 표시 상태로 카드 상태를 고른다.
  ///
  /// 시간 안의 만료·응답 없음은 아직 처리할 수 있으므로 진행 중으로 본다.
  static HomeFocusState resolve({
    required bool hasRoutinesToday,
    required bool hasCurrent,
    required bool hasNext,
    required RoutineLogStatus? currentStatus,
  }) {
    if (!hasRoutinesToday) return empty;
    if (!hasCurrent) return hasNext ? upcoming : dayDone;
    return switch (currentStatus) {
      RoutineLogStatus.completed => completed,
      RoutineLogStatus.skipped => skipped,
      RoutineLogStatus.snoozed => snoozed,
      _ => active,
    };
  }
}

/// 하루가 끝난 뒤 첫 카드가 말하는 결과.
class HomeDayResult {
  const HomeDayResult({
    required this.completed,
    required this.skipped,
    required this.missed,
  });

  final int completed;
  final int skipped;

  /// 시간이 지나도록 기록하지 않은 루틴 (만료·응답 없음·미룬 채 지남).
  final int missed;
}
