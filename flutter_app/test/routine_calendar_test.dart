import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/domain/calendar/routine_calendar.dart';
import 'package:routine_timer/domain/models/routine.dart';

void main() {
  test('month grid starts on Monday and always has six weeks', () {
    final dates = RoutineCalendar.monthGridDates(DateTime(2026, 8));

    expect(dates, hasLength(42));
    expect(dates.first, DateTime(2026, 7, 27));
    expect(dates.last, DateTime(2026, 9, 6));
  });

  test('date projection filters repeat weekdays and sorts by start time', () {
    final routines = [
      const Routine(
        id: 'late',
        title: '저녁 독서',
        startMinutesFromMidnight: 19 * 60,
        endMinutesFromMidnight: 20 * 60,
        repeatWeekdays: {DateTime.thursday},
        colorValue: 0xFFF2C14E,
        iconEmoji: '📚',
      ),
      const Routine(
        id: 'early',
        title: '아침 산책',
        startMinutesFromMidnight: 8 * 60,
        endMinutesFromMidnight: 9 * 60,
        repeatWeekdays: {DateTime.thursday},
        colorValue: 0xFF6C4CF1,
        iconEmoji: '🚶',
      ),
      const Routine(
        id: 'friday',
        title: '금요일 루틴',
        startMinutesFromMidnight: 8 * 60,
        endMinutesFromMidnight: 9 * 60,
        repeatWeekdays: {DateTime.friday},
        colorValue: 0xFFE5866B,
        iconEmoji: '✨',
      ),
    ];

    final thursday = RoutineCalendar.routinesForDate(
      DateTime(2026, 8, 6),
      routines,
    );

    expect(thursday.map((routine) => routine.id), ['early', 'late']);
  });
}
