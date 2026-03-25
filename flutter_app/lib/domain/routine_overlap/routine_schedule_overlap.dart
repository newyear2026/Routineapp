import '../models/routine.dart';

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
    if (a.repeatWeekdays.intersection(b.repeatWeekdays).isEmpty) {
      return false;
    }
    return timeIntervalsOverlap(
      a.startMinutesFromMidnight,
      a.endMinutesFromMidnight,
      b.startMinutesFromMidnight,
      b.endMinutesFromMidnight,
    );
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
}
