import '../models/routine.dart';

/// 루틴 반복 규칙을 월간 캘린더와 날짜별 목록에 투영하는 순수 함수 모음.
abstract final class RoutineCalendar {
  /// 월요일부터 시작하는 6주(42일) 달력 그리드.
  static List<DateTime> monthGridDates(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    final gridStart = firstDay.subtract(Duration(days: firstDay.weekday - 1));
    return List.generate(
      42,
      (index) => DateTime(
        gridStart.year,
        gridStart.month,
        gridStart.day + index,
      ),
    );
  }

  static DateTime previousMonth(DateTime month) =>
      DateTime(month.year, month.month - 1);

  static DateTime nextMonth(DateTime month) =>
      DateTime(month.year, month.month + 1);

  static bool sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// 해당 날짜의 요일에 반복되는 루틴을 시작 시간 순으로 반환한다.
  static List<Routine> routinesForDate(
    DateTime date,
    List<Routine> allRoutines,
  ) {
    final routines = allRoutines
        .where((routine) => routine.repeatWeekdays.contains(date.weekday))
        .toList();
    routines.sort((a, b) {
      final time = a.startMinutesFromMidnight.compareTo(
        b.startMinutesFromMidnight,
      );
      if (time != 0) return time;
      return a.id.compareTo(b.id);
    });
    return routines;
  }
}
