import '../models/routine.dart';
import '../models/routine_log.dart';
import '../models/routine_log_status.dart';
import 'daily_routine_progress.dart';

/// 오늘 진행률·로그 그룹 — **순수 함수** (UI/시간 의존 없음)
///
/// [todayRoutines]: 이미 요일 필터·정렬된 오늘의 [Routine] 목록
/// [logsToday]: 해당 로컬 날짜(`yyyy-MM-dd`)의 [RoutineLog] 목록
///
/// **진행률**: `total` = 오늘 루틴 개수, `completed` = 그중 `RoutineLogStatus.completed`인
/// **서로 다른 routineId** 개수, `remaining = total - completed`,
/// `percent = round(completed / total * 100)` — `total == 0`이면 `percent = 0`.
abstract final class DailyProgressCalculator {
  static DailyRoutineProgressResult calculateProgress(
    List<Routine> todayRoutines,
    List<RoutineLog> logsToday,
  ) {
    final routineIds = todayRoutines.map((r) => r.id).toSet();
    final relevant = logsToday.where((l) => routineIds.contains(l.routineId));

    final completedIds = relevant
        .where((l) => l.status == RoutineLogStatus.completed)
        .map((l) => l.routineId)
        .toSet();
    final total = todayRoutines.length;
    final completed = total > 0 ? completedIds.length.clamp(0, total) : 0;
    final remaining = total > 0 ? (total - completed).clamp(0, total) : 0;
    final percent =
        total > 0 ? ((completed / total) * 100).round().clamp(0, 100) : 0;

    return DailyRoutineProgressResult(
      total: total,
      completed: completed,
      remaining: remaining,
      percent: percent,
    );
  }

  /// 로그를 상태 그룹으로 분류 (completed / snoozed / skipped / no_response / other)
  ///
  /// [routineIdsFilter]가 있으면 해당 루틴 id에 대한 로그만 포함
  static RoutineLogsByStatusGroup groupLogsByStatus(
    List<RoutineLog> logsToday, {
    Set<String>? routineIdsFilter,
  }) {
    final Iterable<RoutineLog> src = routineIdsFilter == null
        ? logsToday
        : logsToday.where((l) => routineIdsFilter.contains(l.routineId));

    final completed = <RoutineLog>[];
    final snoozed = <RoutineLog>[];
    final skipped = <RoutineLog>[];
    final noResponse = <RoutineLog>[];
    final other = <RoutineLog>[];

    for (final log in src) {
      switch (log.status) {
        case RoutineLogStatus.completed:
          completed.add(log);
          break;
        case RoutineLogStatus.snoozed:
          snoozed.add(log);
          break;
        case RoutineLogStatus.skipped:
          skipped.add(log);
          break;
        case RoutineLogStatus.noResponse:
          noResponse.add(log);
          break;
        case RoutineLogStatus.scheduled:
        case RoutineLogStatus.active:
        case RoutineLogStatus.expired:
          other.add(log);
          break;
      }
    }

    return RoutineLogsByStatusGroup(
      completed: List<RoutineLog>.unmodifiable(completed),
      snoozed: List<RoutineLog>.unmodifiable(snoozed),
      skipped: List<RoutineLog>.unmodifiable(skipped),
      noResponse: List<RoutineLog>.unmodifiable(noResponse),
      other: List<RoutineLog>.unmodifiable(other),
    );
  }
}
