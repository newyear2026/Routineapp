import '../models/routine_log.dart';

/// 오늘 루틴 대비 완료 진행률 — [calculateProgress] / [DailyProgressCalculator.calculateProgress] 결과
class DailyRoutineProgressResult {
  const DailyRoutineProgressResult({
    required this.total,
    required this.completed,
    required this.remaining,
    required this.percent,
  });

  /// 오늘 스케줄에 포함된 루틴 수
  final int total;

  /// `RoutineLogStatus.completed`인 **서로 다른 routineId** 수 (오늘 스케줄 내)
  final int completed;

  /// `total - completed` (total이 0이면 0)
  final int remaining;

  /// `completed / total * 100` 반올림, total이 0이면 0
  final int percent;
}

/// 오늘 날짜 로그를 요청한 4개 그룹 + 그 외 상태
class RoutineLogsByStatusGroup {
  const RoutineLogsByStatusGroup({
    required this.completed,
    required this.snoozed,
    required this.skipped,
    required this.noResponse,
    required this.other,
  });

  final List<RoutineLog> completed;
  final List<RoutineLog> snoozed;
  final List<RoutineLog> skipped;
  final List<RoutineLog> noResponse;

  /// `scheduled`, `active`, `expired` 등 위 4그룹에 속하지 않는 로그
  final List<RoutineLog> other;

  int get totalCount =>
      completed.length +
      snoozed.length +
      skipped.length +
      noResponse.length +
      other.length;
}
