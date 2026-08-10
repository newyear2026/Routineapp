import '../../domain/models/routine.dart';
import '../../theme/routine_palette.dart';

/// 최초 실행 시 기본 루틴 (기존 home_dummy 흐름과 유사)
abstract final class RoutineSeed {
  static List<Routine> defaultRoutines() {
    return [
      const Routine(
        id: 'wake',
        title: '기상',
        startMinutesFromMidnight: 6 * 60,
        endMinutesFromMidnight: 7 * 60,
        repeatWeekdays: {1, 2, 3, 4, 5, 6, 7},
        colorValue: RoutinePalette.coralValue,
        iconEmoji: '',
        memo: '하루를 시작해요.',
        updatedAtMs: 1,
      ),
      const Routine(
        id: 'study',
        title: '공부',
        startMinutesFromMidnight: 14 * 60,
        endMinutesFromMidnight: 16 * 60,
        repeatWeekdays: {1, 2, 3, 4, 5},
        colorValue: RoutinePalette.lavenderValue,
        iconEmoji: '',
        memo: '휴대폰은 잠시 멀리 두고, 지금은 학습에만 집중해봐요.',
        updatedAtMs: 2,
      ),
      const Routine(
        id: 'rest',
        title: '휴식',
        startMinutesFromMidnight: 16 * 60,
        endMinutesFromMidnight: 17 * 60,
        repeatWeekdays: {1, 2, 3, 4, 5},
        colorValue: RoutinePalette.blueValue,
        iconEmoji: '',
        memo: '잠깐 숨 돌리기.',
        updatedAtMs: 3,
      ),
    ];
  }
}
