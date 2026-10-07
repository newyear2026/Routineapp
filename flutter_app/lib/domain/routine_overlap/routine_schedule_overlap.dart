import '../models/routine.dart';
import '../services/routine_occurrences.dart';

/// 같은 날 시간대 겹침 검사 — [currentRoutine] 우선순위와 분리
abstract final class RoutineScheduleOverlap {
  /// `[startA, endA)` 와 `[startB, endB)` 가 겹치는지 (분 단위, 자정 넘김 없음)
  static bool timeIntervalsOverlap(
    int startA,
    int endA,
    int startB,
    int endB,
  ) {
    return startA < endB && endA > startB;
  }

  /// 두 루틴이 **같은 요일을 하나라도 공유**하고, 그날 시간대가 겹치는지
  static bool routinesOverlapOnSharedDay(Routine a, Routine b) {
    for (var weekday = 1; weekday <= 7; weekday++) {
      if (_onDay(a, b, weekday)) return true;
    }
    return false;
  }

  static bool _onDay(Routine a, Routine b, int weekday) {
    final date = DateTime(2026, 1, 5 + weekday - 1);
    final aa = RoutineOccurrences.timeline(date, [a]);
    final bb = RoutineOccurrences.timeline(date, [b]);
    for (final ra in aa) {
      for (final rb in bb) {
        for (final sa in RoutineOccurrences.segments(ra, date)) {
          for (final sb in RoutineOccurrences.segments(rb, date)) {
            if (timeIntervalsOverlap(sa.start, sa.end, sb.start, sb.end)) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  /// [candidate]와 겹치는 루틴 — [excludeRoutineId]는 편집 시 목록 속 자기 자신 제외
  static List<Routine> conflictingRoutines({
    required Routine candidate,
    required List<Routine> allRoutines,
    String? excludeRoutineId,
  }) {
    final out = <Routine>[];
    for (final r in allRoutines) {
      if (excludeRoutineId != null && r.id == excludeRoutineId) continue;
      if (routinesOverlapOnSharedDay(candidate, r)) out.add(r);
    }
    return out;
  }

  /// [weekday] 기준으로 [candidate]와 시간대가 겹치는 루틴
  static List<Routine> conflictingRoutinesOnWeekday({
    required Routine candidate,
    required List<Routine> allRoutines,
    required int weekday,
    String? excludeRoutineId,
  }) {
    return allRoutines
        .where((r) => r.id != excludeRoutineId && _onDay(candidate, r, weekday))
        .toList();
  }
}
