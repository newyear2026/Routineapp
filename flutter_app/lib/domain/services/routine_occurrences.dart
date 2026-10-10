import '../models/routine.dart';
import '../models/routine_log.dart';
import '../utils/time_minutes.dart';

/// One date contract everywhere: activity=start date, sleep=wake date.
/// Calendar constructors (not 24-hour durations) preserve local dates across DST.
abstract final class RoutineOccurrences {
  static DateTime day(DateTime d, [int offset = 0]) =>
      DateTime(d.year, d.month, d.day + offset);

  static DateTime dateFor(Routine r, DateTime now) =>
      r.occurrenceDate ??
      day(
          now,
          r.crossesMidnight &&
                  TimeMinutes.fromDateTime(now) >= r.startMinutesFromMidnight
              ? 1
              : 0);

  static Routine onDate(Routine r, DateTime date) =>
      r.copyWith(occurrenceDate: day(date));

  static ({DateTime start, DateTime end, DateTime date}) window(
      Routine r, DateTime reference) {
    final date = dateFor(r, reference);
    final startDay = day(date, r.crossesMidnight ? -1 : 0);
    return (
      date: date,
      start: DateTime(startDay.year, startDay.month, startDay.day, 0,
          r.startMinutesFromMidnight),
      end: DateTime(
          date.year, date.month, date.day, 0, r.endMinutesFromMidnight),
    );
  }

  static bool active(Routine r, DateTime now) {
    final w = window(r, now);
    return r.repeatWeekdays.contains(w.date.weekday) &&
        !now.isBefore(w.start) &&
        now.isBefore(w.end);
  }

  static RoutineLog? logFor(Routine r, List<RoutineLog> logs, DateTime now) {
    final date = TimeMinutes.dateYmd(dateFor(r, now));
    return logs
        .where((l) => l.routineId == r.id && l.dateYmd == date)
        .firstOrNull;
  }

  /// Daily goals/logs count a sleep once on its wake date, not on both segments.
  static List<Routine> ownedByDate(DateTime date, List<Routine> all) {
    final out = [
      for (final r in all)
        if (r.repeatWeekdays.contains(date.weekday))
          r.isSleep ? onDate(r, date) : r
    ];
    out.sort((a, b) {
      final start = window(a, date).start.compareTo(window(b, date).start);
      if (start != 0) return start;
      final version = b.updatedAtMs.compareTo(a.updatedAtMs);
      return version != 0 ? version : a.id.compareTo(b.id);
    });
    return out;
  }

  /// Occurrences intersecting this civil day, including tonight's next wake date.
  static List<Routine> timeline(DateTime date, List<Routine> all) {
    final start = day(date), end = day(date, 1);
    final out = <Routine>[];
    for (final r in all) {
      if (!r.isSleep) {
        if (r.repeatWeekdays.contains(date.weekday)) out.add(r);
        continue;
      }
      for (final anchor in [start, end]) {
        if (!r.repeatWeekdays.contains(anchor.weekday)) continue;
        final projected = onDate(r, anchor);
        final w = window(projected, date);
        if (w.start.isBefore(end) && w.end.isAfter(start)) out.add(projected);
      }
    }
    out.sort((a, b) {
      final order = window(a, date).start.compareTo(window(b, date).start);
      if (order != 0) return order;
      final version = b.updatedAtMs.compareTo(a.updatedAtMs);
      return version != 0 ? version : a.id.compareTo(b.id);
    });
    return out;
  }

  static List<({int start, int end})> segments(Routine r, DateTime date) {
    final w = window(r, date);
    final origin = day(date), end = day(date, 1);
    if (!w.start.isBefore(end) || !w.end.isAfter(origin)) return [];
    // Clock minutes, rather than elapsed duration, for the 24-hour dial.
    final start =
        w.start.isBefore(origin) ? 0 : TimeMinutes.fromDateTime(w.start);
    final finish =
        !w.end.isBefore(end) ? 1440 : TimeMinutes.fromDateTime(w.end);
    return start < finish ? [(start: start, end: finish)] : [];
  }
}
