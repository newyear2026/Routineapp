import '../../domain/models/routine.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/routine_palette.dart';

/// 최초 실행 시 기본 루틴 (기존 home_dummy 흐름과 유사)
abstract final class RoutineSeed {
  /// 이름·메모는 저장되는 사용자 데이터이므로 현재 언어로 만든다.
  static List<Routine> defaultRoutines(AppLocalizations l10n) {
    return [
      Routine(
        id: 'wake',
        title: l10n.catalogWakeUp,
        startMinutesFromMidnight: 6 * 60,
        endMinutesFromMidnight: 7 * 60,
        repeatWeekdays: {1, 2, 3, 4, 5, 6, 7},
        colorValue: RoutinePalette.coralValue,
        iconEmoji: '',
        memo: l10n.seedWakeUpMemo,
        updatedAtMs: 1,
      ),
      Routine(
        id: 'study',
        title: l10n.catalogStudy,
        startMinutesFromMidnight: 14 * 60,
        endMinutesFromMidnight: 16 * 60,
        repeatWeekdays: {1, 2, 3, 4, 5},
        colorValue: RoutinePalette.lavenderValue,
        iconEmoji: '',
        memo: l10n.seedStudyMemo,
        updatedAtMs: 2,
      ),
      Routine(
        id: 'rest',
        title: l10n.catalogBreak,
        startMinutesFromMidnight: 16 * 60,
        endMinutesFromMidnight: 17 * 60,
        repeatWeekdays: {1, 2, 3, 4, 5},
        colorValue: RoutinePalette.blueValue,
        iconEmoji: '',
        memo: l10n.seedBreakMemo,
        updatedAtMs: 3,
      ),
    ];
  }
}
