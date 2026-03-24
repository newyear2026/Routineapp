import '../../domain/models/routine.dart';

/// 최초 실행 시 기본 루틴 (기존 home_dummy 흐름과 유사)
abstract final class RoutineSeed {
  static List<Routine> defaultRoutines() {
    return [
      Routine(
        id: 'wake',
        title: '기상',
        startMinutesFromMidnight: 6 * 60,
        endMinutesFromMidnight: 7 * 60,
        repeatWeekdays: {1, 2, 3, 4, 5, 6, 7},
        colorValue: 0xFFFFE4E9,
        iconEmoji: '🌅',
        memo: '하루를 시작해요.',
      ),
      Routine(
        id: 'study',
        title: '공부',
        startMinutesFromMidnight: 14 * 60,
        endMinutesFromMidnight: 16 * 60,
        repeatWeekdays: {1, 2, 3, 4, 5},
        colorValue: 0xFFE8DDFA,
        iconEmoji: '📚',
        memo: '휴대폰은 잠시 멀리 두고, 지금은 학습에만 집중해봐요.',
      ),
      Routine(
        id: 'rest',
        title: '휴식',
        startMinutesFromMidnight: 16 * 60,
        endMinutesFromMidnight: 17 * 60,
        repeatWeekdays: {1, 2, 3, 4, 5},
        colorValue: 0xFFD4E4FF,
        iconEmoji: '☕',
        memo: '잠깐 숨 돌리기.',
      ),
    ];
  }
}
