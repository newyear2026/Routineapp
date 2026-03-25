import '../models/routine.dart';
import 'home_routine_schedule.dart';

/// 현재/다음 루틴 슬롯 — 구현은 [HomeRoutineSchedule]
class RoutineScheduleService {
  const RoutineScheduleService();

  /// 해당 로컬 날짜의 요일에 맞는 루틴, 시작 시각 순
  List<Routine> routinesForDate(DateTime dateLocal, List<Routine> all) =>
      HomeRoutineSchedule.getTodayRoutines(dateLocal, all);

  /// 현재 시각이 구간 안에 있는 루틴
  Routine? currentRoutineAt(DateTime nowLocal, List<Routine> todaysSorted) =>
      HomeRoutineSchedule.getCurrentRoutine(nowLocal, todaysSorted);

  /// 같은 날 기준 다음 루틴 (슬롯 안이면 그다음, 아니면 다음 시작 예정)
  Routine? nextRoutineAfter(DateTime nowLocal, List<Routine> todaysSorted) =>
      HomeRoutineSchedule.getNextRoutine(nowLocal, todaysSorted);

  Routine? routineAfter(Routine anchor, List<Routine> sortedToday) =>
      HomeRoutineSchedule.routineAfter(anchor, sortedToday);
}
