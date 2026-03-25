import '../../domain/models/routine.dart';
import '../../domain/utils/time_minutes.dart';
import '../../models/home_models.dart';

/// 도메인 [Routine] → 홈 UI용 [RoutineSegment] / [CurrentRoutine] 등
abstract final class HomeViewMapper {
  static List<RoutineSegment> toSegments(List<Routine> todaysSorted) {
    return todaysSorted
        .map(
          (r) => RoutineSegment(
            id: r.id,
            startMinutesFromMidnight: r.startMinutesFromMidnight,
            label: r.title,
            emoji: r.iconEmoji,
            color: r.color,
          ),
        )
        .toList();
  }

  static List<String> weekdayLabels(Set<int> weekdays) {
    const map = {
      1: '월',
      2: '화',
      3: '수',
      4: '목',
      5: '금',
      6: '토',
      7: '일',
    };
    final sorted = weekdays.toList()..sort();
    return sorted.map((d) => map[d] ?? '').where((s) => s.isNotEmpty).toList();
  }

  static CurrentRoutine toCurrentRoutine(
    Routine r,
    int progressPercent,
  ) {
    return CurrentRoutine(
      id: r.id,
      name: r.title,
      emoji: r.iconEmoji,
      startTime: TimeMinutes.formatHm(r.startMinutesFromMidnight),
      endTime: TimeMinutes.formatHm(r.endMinutesFromMidnight),
      progress: progressPercent.clamp(0, 100),
      repeatDays: weekdayLabels(r.repeatWeekdays),
      memo: r.memo ?? '',
    );
  }

  static NextRoutine? toNextRoutine(Routine? r) {
    if (r == null) return null;
    return NextRoutine(
      name: r.title,
      emoji: r.iconEmoji,
      time: TimeMinutes.formatHm(r.startMinutesFromMidnight),
    );
  }

  static CharacterCopy characterFor(Routine r) {
    return CharacterCopy(
      emoji: '🐻',
      highlightEmoji: r.iconEmoji,
      highlightRoutineName: r.title,
    );
  }

  /// [CurrentRoutine] id만 링 강조에 사용 (표시용 필드 채움)
  static CurrentRoutine ringStubFromRoutine(Routine r) {
    return CurrentRoutine(
      id: r.id,
      name: r.title,
      emoji: r.iconEmoji,
      startTime: TimeMinutes.formatHm(r.startMinutesFromMidnight),
      endTime: TimeMinutes.formatHm(r.endMinutesFromMidnight),
      progress: 0,
      repeatDays: weekdayLabels(r.repeatWeekdays),
      memo: r.memo ?? '',
    );
  }
}
