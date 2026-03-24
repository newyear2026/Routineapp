import '../models/routine.dart';
import '../utils/time_minutes.dart';
import '../utils/time_calculation.dart';

/// 현재/다음 루틴 슬롯 계산 — [RoutineDayService]에서 위임 가능
class RoutineScheduleService {
  const RoutineScheduleService();

  /// 해당 로컬 날짜의 요일에 맞는 루틴, 시작 시각 순
  List<Routine> routinesForDate(DateTime dateLocal, List<Routine> all) {
    final wd = dateLocal.weekday;
    final filtered = all.where((r) => r.repeatWeekdays.contains(wd)).toList();
    filtered.sort((a, b) => a.startMinutesFromMidnight
        .compareTo(b.startMinutesFromMidnight));
    return filtered;
  }

  /// 현재 시각이 구간 안에 있는 루틴
  Routine? currentRoutineAt(DateTime nowLocal, List<Routine> todaysSorted) {
    final m = TimeMinutes.fromDateTime(nowLocal);
    for (final r in todaysSorted) {
      if (TimeCalculation.containsMinuteInOpenInterval(
        m,
        r.startMinutesFromMidnight,
        r.endMinutesFromMidnight,
      )) {
        return r;
      }
    }
    return null;
  }

  /// 같은 날 기준 다음 루틴 (시간대 없으면 곧 시작할 루틴)
  Routine? nextRoutineAfter(DateTime nowLocal, List<Routine> todaysSorted) {
    final m = TimeMinutes.fromDateTime(nowLocal);
    final current = currentRoutineAt(nowLocal, todaysSorted);
    if (current != null) {
      final idx = todaysSorted.indexWhere((e) => e.id == current.id);
      if (idx >= 0 && idx < todaysSorted.length - 1) {
        return todaysSorted[idx + 1];
      }
      return null;
    }
    for (final r in todaysSorted) {
      if (m < r.startMinutesFromMidnight) {
        return r;
      }
    }
    return null;
  }

  Routine? routineAfter(Routine anchor, List<Routine> sortedToday) {
    final i = sortedToday.indexWhere((e) => e.id == anchor.id);
    if (i < 0 || i >= sortedToday.length - 1) return null;
    return sortedToday[i + 1];
  }
}
