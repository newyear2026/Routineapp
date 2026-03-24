import '../models/routine.dart';
import '../models/routine_log.dart';
import '../models/routine_log_status.dart';
import '../utils/time_calculation.dart';

/// 시간대(스케줄) + 저장된 [RoutineLog]를 합쳐 **화면/판단용** 상태를 결정한다.
///
/// - `completed` / `skipped` 등 **명시 저장 상태**는 시간 기반보다 우선 (단, snoozed 만료 후 재평가)
abstract final class RoutineStateResolver {
  /// 최종 표시/판단용 상태 (7종과 동일 enum 재사용)
  static RoutineLogStatus effectiveStatus({
    required Routine routine,
    required RoutineLog? log,
    required DateTime nowLocal,
  }) {
    final m = nowLocal.hour * 60 + nowLocal.minute;
    final inWindow = TimeCalculation.containsMinuteInOpenInterval(
      m,
      routine.startMinutesFromMidnight,
      routine.endMinutesFromMidnight,
    );
    final beforeStart = m < routine.startMinutesFromMidnight;
    final afterEnd = m >= routine.endMinutesFromMidnight;

    if (log != null) {
      switch (log.status) {
        case RoutineLogStatus.completed:
          return RoutineLogStatus.completed;
        case RoutineLogStatus.skipped:
          return RoutineLogStatus.skipped;
        case RoutineLogStatus.snoozed:
          final until = log.snoozedUntilMs;
          if (until != null && nowLocal.millisecondsSinceEpoch < until) {
            return RoutineLogStatus.snoozed;
          }
          break;
        case RoutineLogStatus.expired:
        case RoutineLogStatus.noResponse:
          return log.status;
        case RoutineLogStatus.scheduled:
        case RoutineLogStatus.active:
          break;
      }
    }

    if (inWindow) {
      return RoutineLogStatus.active;
    }
    if (beforeStart) {
      return RoutineLogStatus.scheduled;
    }
    if (afterEnd) {
      return RoutineLogStatus.expired;
    }
    return RoutineLogStatus.scheduled;
  }

  /// 오늘 이 루틴에 대해 사용자 액션(완료/스킵/스누즈)을 더 받을 수 있는지
  static bool canApplyUserAction({
    required Routine routine,
    required RoutineLog? log,
    required DateTime nowLocal,
  }) {
    final m = nowLocal.hour * 60 + nowLocal.minute;
    final inWindow = TimeCalculation.containsMinuteInOpenInterval(
      m,
      routine.startMinutesFromMidnight,
      routine.endMinutesFromMidnight,
    );
    if (!inWindow) return false;

    if (log == null) return true;

    switch (log.status) {
      case RoutineLogStatus.completed:
      case RoutineLogStatus.skipped:
        return false;
      case RoutineLogStatus.snoozed:
        final until = log.snoozedUntilMs;
        if (until != null && nowLocal.millisecondsSinceEpoch < until) {
          return true;
        }
        return true;
      case RoutineLogStatus.scheduled:
      case RoutineLogStatus.active:
      case RoutineLogStatus.expired:
      case RoutineLogStatus.noResponse:
        return true;
    }
  }
}
