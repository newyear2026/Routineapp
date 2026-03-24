import '../models/routine.dart';
import '../models/routine_log.dart';
import 'daily_progress_calculator.dart';
import 'daily_routine_progress.dart';

export 'daily_progress_calculator.dart';
export 'daily_routine_progress.dart';

/// 화면·서비스에서 그대로 import 해 쓰기 위한 최상위 함수
DailyRoutineProgressResult calculateProgress(
  List<Routine> todayRoutines,
  List<RoutineLog> logsToday,
) =>
    DailyProgressCalculator.calculateProgress(todayRoutines, logsToday);

RoutineLogsByStatusGroup groupLogsByStatus(
  List<RoutineLog> logsToday, {
  Set<String>? routineIdsFilter,
}) =>
    DailyProgressCalculator.groupLogsByStatus(
      logsToday,
      routineIdsFilter: routineIdsFilter,
    );
