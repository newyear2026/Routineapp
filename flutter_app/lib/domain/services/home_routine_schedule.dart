import '../models/routine.dart';
import '../routine_overlap/current_routine_slot_resolver.dart';
import 'routine_occurrences.dart';

/// Civil-day schedule shared by home and timeline consumers.
/// Sleep dates are projected through RoutineOccurrences; definitions are unchanged.
abstract final class HomeRoutineSchedule {
  /// 해당 날짜를 지나는 회차 — 수면은 전날부터 이어진 회차와 오늘 밤 회차를 구분한다.
  static List<Routine> getTodayRoutines(
    DateTime dateLocal,
    List<Routine> allRoutines,
  ) {
    return RoutineOccurrences.timeline(dateLocal, allRoutines);
  }

  /// [todaySorted] 안에서 지금 시각이 `[start, end)` 구간에 들어가는 루틴 — 겹침 시 [Routine.updatedAtMs] 최신 우선
  static Routine? getCurrentRoutine(
    DateTime nowLocal,
    List<Routine> todaySorted,
  ) {
    return CurrentRoutineSlotResolver.pickCurrentRoutine(nowLocal, todaySorted);
  }

  /// 현재 슬롯이 있으면 시간순 **바로 다음** 루틴, 없으면 아직 시작 전인 **가장 가까운** 루틴
  static Routine? getNextRoutine(
    DateTime nowLocal,
    List<Routine> todaySorted,
  ) {
    final current = getCurrentRoutine(nowLocal, todaySorted);
    if (current != null) {
      final idx = todaySorted
          .indexWhere((e) => e.occurrenceKey == current.occurrenceKey);
      if (idx >= 0 && idx < todaySorted.length - 1) {
        return todaySorted[idx + 1];
      }
      return null;
    }
    for (final r in todaySorted) {
      if (nowLocal.isBefore(RoutineOccurrences.window(r, nowLocal).start)) {
        return r;
      }
    }
    return null;
  }

  /// A sleep that ends tomorrow can show tomorrow's next activity immediately.
  /// Ordinary routines retain the existing same-day horizon.
  static List<Routine> throughWakeDay(
      DateTime now, List<Routine> today, List<Routine> all) {
    final display = getCurrentRoutine(now, today) ?? getNextRoutine(now, today);
    if (display == null || !display.crossesMidnight) return today;
    final wakeDate = RoutineOccurrences.window(display, now).date;
    if (!wakeDate.isAfter(RoutineOccurrences.day(now))) return today;
    final seen = today.map((r) => r.occurrenceKey).toSet();
    final result = [...today];
    for (final r in RoutineOccurrences.timeline(wakeDate, all)) {
      final occurrence =
          r.occurrenceDate == null ? RoutineOccurrences.onDate(r, wakeDate) : r;
      if (seen.add(occurrence.occurrenceKey)) result.add(occurrence);
    }
    result.sort((a, b) => RoutineOccurrences.window(a, now)
        .start
        .compareTo(RoutineOccurrences.window(b, now).start));
    return result;
  }

  /// 같은 날 목록에서 [anchor] 다음 시간순 루틴 (카드 '다음' 영역용)
  static Routine? routineAfter(Routine anchor, List<Routine> sortedToday) {
    final i =
        sortedToday.indexWhere((e) => e.occurrenceKey == anchor.occurrenceKey);
    if (i < 0 || i >= sortedToday.length - 1) return null;
    return sortedToday[i + 1];
  }

  /// [anchor] **이후의 모든** 시간순 루틴 (Home '다음 일정' 목록용)
  ///
  /// [routineAfter]가 첫 항목만 돌려주기 때문에, 화면에서 여러 개를 보여줄 때
  /// 같은 루틴을 두 번 넣는 실수를 막으려면 이 목록 하나만 소비한다.
  static List<Routine> routinesAfter(
    Routine anchor,
    List<Routine> sortedToday,
  ) {
    final i =
        sortedToday.indexWhere((e) => e.occurrenceKey == anchor.occurrenceKey);
    if (i < 0 || i >= sortedToday.length - 1) return const <Routine>[];
    return List<Routine>.unmodifiable(sortedToday.sublist(i + 1));
  }
}
