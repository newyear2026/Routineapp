import '../models/routine.dart';
import '../models/routine_log.dart';
import 'daily_progress_calculator.dart';
import 'daily_routine_progress.dart';

export 'daily_progress_calculator.dart';
export 'daily_routine_progress.dart';

/// [DailyProgressCalculator.calculateProgress] — Home·Progress 동일 기준
DailyRoutineProgressResult calculateProgress(
  List<Routine> todayRoutines,
  List<RoutineLog> logsToday,
) =>
    DailyProgressCalculator.calculateProgress(todayRoutines, logsToday);

/// [DailyProgressCalculator.groupLogsByStatus]
RoutineLogsByStatusGroup groupLogsByStatus(
  List<RoutineLog> logsToday, {
  Set<String>? routineIdsFilter,
}) =>
    DailyProgressCalculator.groupLogsByStatus(
      logsToday,
      routineIdsFilter: routineIdsFilter,
    );
