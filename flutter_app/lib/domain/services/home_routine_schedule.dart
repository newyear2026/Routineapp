import '../models/routine.dart';
import '../routine_overlap/current_routine_slot_resolver.dart';
import '../utils/time_to_minutes.dart';

/// Home·스케줄용 — [Routine]의 `startMinutesFromMidnight` / `endMinutesFromMidnight` / `repeatWeekdays`만 사용
///
/// - 오늘 요일(`dateLocal.weekday`)에 해당하는 루틴만 [getTodayRoutines] 결과에 포함
/// - 현재 시각은 [timeToMinutes]로 분 단위로 통일
abstract final class HomeRoutineSchedule {
  /// 오늘(로컬 날짜 기준) 반복에 포함된 루틴, 시작 분 오름차순
  static List<Routine> getTodayRoutines(
    DateTime dateLocal,
    List<Routine> allRoutines,
  ) {
    final wd = dateLocal.weekday;
    final filtered =
        allRoutines.where((r) => r.repeatWeekdays.contains(wd)).toList();
    filtered.sort((a, b) {
      final s =
          a.startMinutesFromMidnight.compareTo(b.startMinutesFromMidnight);
      if (s != 0) return s;
      final u = b.updatedAtMs.compareTo(a.updatedAtMs);
      if (u != 0) return u;
      return a.id.compareTo(b.id);
    });
    return filtered;
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
    final m = timeToMinutes(nowLocal);
    final current = getCurrentRoutine(nowLocal, todaySorted);
    if (current != null) {
      final idx = todaySorted.indexWhere((e) => e.id == current.id);
      if (idx >= 0 && idx < todaySorted.length - 1) {
        return todaySorted[idx + 1];
      }
      return null;
    }
    for (final r in todaySorted) {
      if (m < r.startMinutesFromMidnight) {
        return r;
      }
    }
    return null;
  }

  /// 같은 날 목록에서 [anchor] 다음 시간순 루틴 (카드 '다음' 영역용)
  static Routine? routineAfter(Routine anchor, List<Routine> sortedToday) {
    final i = sortedToday.indexWhere((e) => e.id == anchor.id);
    if (i < 0 || i >= sortedToday.length - 1) return null;
    return sortedToday[i + 1];
  }
}
