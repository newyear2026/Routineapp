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
            endMinutesFromMidnight: r.endMinutesFromMidnight,
            label: r.title,
            emoji: r.iconEmoji,
            color: r.color,
          ),
        )
        .toList();
  }

  static CurrentRoutine toCurrentRoutine(
    Routine r,
    int progressPercent,
    String timingHint,
  ) {
    return CurrentRoutine(
      id: r.id,
      name: r.title,
      emoji: r.iconEmoji,
      startTime: TimeMinutes.formatHm(r.startMinutesFromMidnight),
      endTime: TimeMinutes.formatHm(r.endMinutesFromMidnight),
      timingHint: timingHint,
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
      timingHint: '',
      progress: 0,
      repeatDays: weekdayLabels(r.repeatWeekdays),
      memo: r.memo ?? '',
    );
  }
}
