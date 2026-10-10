import '../models/routine.dart';
import '../services/routine_occurrences.dart';

/// 현재 시각이 속한 슬롯에 **여러 루틴**이 있을 때 — [Routine.updatedAtMs] 최신 우선
///
/// [RoutineScheduleOverlap] 과 역할 분리
abstract final class CurrentRoutineSlotResolver {
  static Routine? pickCurrentRoutine(
    DateTime nowLocal,
    List<Routine> todaySorted,
  ) {
    final inWindow = <Routine>[];
    for (final r in todaySorted) {
      if (RoutineOccurrences.active(r, nowLocal)) {
        inWindow.add(r);
      }
    }
    if (inWindow.isEmpty) return null;
    if (inWindow.length == 1) return inWindow.first;
    inWindow.sort((a, b) {
      final u = b.updatedAtMs.compareTo(a.updatedAtMs);
      if (u != 0) return u;
      final s =
          a.startMinutesFromMidnight.compareTo(b.startMinutesFromMidnight);
      if (s != 0) return s;
      return a.id.compareTo(b.id);
    });
    return inWindow.first;
  }
}
