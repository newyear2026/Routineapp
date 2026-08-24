import '../../domain/models/routine.dart';
import '../../domain/utils/app_date_formats.dart';
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
    String localeName,
  ) {
    return CurrentRoutine(
      id: r.id,
      name: r.title,
      emoji: r.iconEmoji,
      startTime: TimeMinutes.formatHm(r.startMinutesFromMidnight),
      endTime: TimeMinutes.formatHm(r.endMinutesFromMidnight),
      timingHint: timingHint,
      progress: progressPercent.clamp(0, 100),
      repeatDays: _weekdayLabels(r.repeatWeekdays, localeName),
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
  static CurrentRoutine ringStubFromRoutine(Routine r, String localeName) {
    return CurrentRoutine(
      id: r.id,
      name: r.title,
      emoji: r.iconEmoji,
      startTime: TimeMinutes.formatHm(r.startMinutesFromMidnight),
      endTime: TimeMinutes.formatHm(r.endMinutesFromMidnight),
      timingHint: '',
      progress: 0,
      repeatDays: _weekdayLabels(r.repeatWeekdays, localeName),
      memo: r.memo ?? '',
    );
  }

  /// 반복 요일 약어 목록 — 요일 이름은 로케일에서 가져온다.
  static List<String> _weekdayLabels(Set<int> weekdays, String localeName) {
    final sorted = weekdays.where((d) => d >= 1 && d <= 7).toList()..sort();
    return sorted
        .map((d) => AppDateFormats.weekdayShortByIndexIn(localeName, d))
        .toList();
  }
}
