import '../domain/models/routine.dart';
import '../domain/services/routine_occurrences.dart';
import '../domain/utils/time_minutes.dart';

/// A button belongs to the occurrence that was rendered, never the next slot.
class WidgetRoutineTarget {
  const WidgetRoutineTarget(this.routineId, this.dateYmd, this.version,
      this.startMinutes, this.endMinutes);

  factory WidgetRoutineTarget.forRoutine(Routine routine, DateTime now) =>
      WidgetRoutineTarget(
        routine.id,
        TimeMinutes.dateYmd(RoutineOccurrences.dateFor(routine, now)),
        routine.updatedAtMs,
        routine.startMinutesFromMidnight,
        routine.endMinutesFromMidnight,
      );

  final String routineId;
  final String dateYmd;
  final int version;
  final int startMinutes;
  final int endMinutes;

  Uri get uri =>
      Uri(scheme: 'loopet-widget', host: 'complete', queryParameters: {
        'id': routineId,
        'date': dateYmd,
        'version': '$version',
        'start': '$startMinutes',
        'end': '$endMinutes',
      });

  static WidgetRoutineTarget? parse(Uri? uri) {
    if (uri == null ||
        uri.scheme != 'loopet-widget' ||
        uri.host != 'complete') {
      return null;
    }
    final p = uri.queryParameters;
    final date = DateTime.tryParse(p['date'] ?? '');
    final version = int.tryParse(p['version'] ?? '');
    final start = int.tryParse(p['start'] ?? '');
    final end = int.tryParse(p['end'] ?? '');
    if ((p['id'] ?? '').isEmpty ||
        date == null ||
        TimeMinutes.dateYmd(date) != p['date'] ||
        version == null ||
        start == null ||
        end == null ||
        start < 0 ||
        start >= 1440 ||
        end < 0 ||
        end > 1440) {
      return null;
    }
    return WidgetRoutineTarget(p['id']!, p['date']!, version, start, end);
  }

  bool matches(Routine routine) =>
      routine.id == routineId &&
      routine.updatedAtMs == version &&
      routine.startMinutesFromMidnight == startMinutes &&
      routine.endMinutesFromMidnight == endMinutes;
}
