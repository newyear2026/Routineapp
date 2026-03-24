import '../models/routine.dart';
import '../models/routine_log.dart';
import 'routine_progress_service.dart';
import 'routine_schedule_service.dart';

/// 하위 호환용 파사드 — 스케줄·진행률은 각각 전용 서비스로 분리됨
class RoutineDayService {
  const RoutineDayService()
      : _schedule = const RoutineScheduleService(),
        _progress = const RoutineProgressService();

  final RoutineScheduleService _schedule;
  final RoutineProgressService _progress;

  List<Routine> routinesForDate(DateTime dateLocal, List<Routine> all) =>
      _schedule.routinesForDate(dateLocal, all);

  Routine? currentRoutineAt(DateTime nowLocal, List<Routine> todaysSorted) =>
      _schedule.currentRoutineAt(nowLocal, todaysSorted);

  Routine? nextRoutineAfter(DateTime nowLocal, List<Routine> todaysSorted) =>
      _schedule.nextRoutineAfter(nowLocal, todaysSorted);

  int progressPercentInWindow(Routine r, DateTime nowLocal) =>
      _progress.progressPercentInWindow(r, nowLocal);

  ({int completed, int total}) todayProgress(
    List<Routine> todaysSorted,
    List<RoutineLog> logsToday,
  ) =>
      _progress.todayCompletionProgress(todaysSorted, logsToday);

  RoutineLog? logForRoutine(
    String routineId,
    List<RoutineLog> logsToday,
  ) {
    final found =
        logsToday.where((l) => l.routineId == routineId).toList();
    if (found.isEmpty) return null;
    return found.first;
  }

  Routine? routineAfter(Routine anchor, List<Routine> sortedToday) =>
      _schedule.routineAfter(anchor, sortedToday);
}
