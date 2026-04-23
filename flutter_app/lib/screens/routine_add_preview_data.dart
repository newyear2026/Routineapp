import '../domain/models/routine.dart';
import '../domain/routine_overlap/routine_schedule_overlap.dart';

class RoutineAddPreviewData {
  RoutineAddPreviewData._({
    required this.weekdays,
    required this.selectedWeekday,
    required this.previewRoutines,
    required this.dayConflicts,
  });

  factory RoutineAddPreviewData.from({
    required Routine candidate,
    required List<Routine> allRoutines,
    required int? selectedWeekday,
  }) {
    final weekdays = candidate.repeatWeekdays.toList()..sort();
    if (weekdays.isEmpty) {
      return RoutineAddPreviewData._(
        weekdays: weekdays,
        selectedWeekday: null,
        previewRoutines: const [],
        dayConflicts: const [],
      );
    }

    final effectiveWeekday =
        selectedWeekday != null && weekdays.contains(selectedWeekday)
            ? selectedWeekday
            : weekdays.first;

    final previewRoutines = [
      ...allRoutines.where(
        (routine) =>
            routine.id != candidate.id &&
            routine.repeatWeekdays.contains(effectiveWeekday),
      ),
      candidate,
    ]..sort(
        (a, b) => a.startMinutesFromMidnight.compareTo(
          b.startMinutesFromMidnight,
        ),
      );

    final dayConflicts = RoutineScheduleOverlap.conflictingRoutinesOnWeekday(
      candidate: candidate,
      allRoutines: allRoutines,
      weekday: effectiveWeekday,
      excludeRoutineId: candidate.id,
    );

    return RoutineAddPreviewData._(
      weekdays: weekdays,
      selectedWeekday: effectiveWeekday,
      previewRoutines: previewRoutines,
      dayConflicts: dayConflicts,
    );
  }

  final List<int> weekdays;
  final int? selectedWeekday;
  final List<Routine> previewRoutines;
  final List<Routine> dayConflicts;

  bool get hasWeekdays => weekdays.isNotEmpty;
  int get selectedCount => weekdays.length;
  String get weekdayLabel =>
      selectedWeekday == null ? '선택한 요일' : weekdayName(selectedWeekday!);

  static String weekdayName(int weekday) {
    const map = {
      1: '월요일',
      2: '화요일',
      3: '수요일',
      4: '목요일',
      5: '금요일',
      6: '토요일',
      7: '일요일',
    };
    return map[weekday] ?? '선택한 요일';
  }

  static String weekdayShortName(int weekday) {
    const map = {
      1: '월',
      2: '화',
      3: '수',
      4: '목',
      5: '금',
      6: '토',
      7: '일',
    };
    return map[weekday] ?? '';
  }
}
