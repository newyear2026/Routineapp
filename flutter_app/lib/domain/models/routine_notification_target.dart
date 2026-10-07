import 'dart:convert';

import 'routine.dart';
import '../utils/time_minutes.dart';

/// A repeating alarm names a routine/version/weekday, not "whatever is current".
/// The OS delivery timestamp resolves the occurrence, including week-old alerts.
class RoutineNotificationTarget {
  const RoutineNotificationTarget({
    required this.routineId,
    this.weekday,
    this.dateYmd,
    this.updatedAtMs,
    this.startMinutes,
    this.endMinutes,
    this.routineType = RoutineType.activity,
    this.notificationMinutes,
  });

  factory RoutineNotificationTarget.forRoutine(Routine routine,
          {int? weekday, String? dateYmd}) =>
      RoutineNotificationTarget(
        routineId: routine.id,
        weekday: weekday,
        dateYmd: dateYmd,
        updatedAtMs: routine.updatedAtMs,
        startMinutes: routine.startMinutesFromMidnight,
        endMinutes: routine.endMinutesFromMidnight,
        routineType: routine.type,
        notificationMinutes: routine.isSleep
            ? routine.endMinutesFromMidnight
            : routine.startMinutesFromMidnight,
      );

  final String routineId;
  final int? weekday;
  final String? dateYmd;
  final int? updatedAtMs;
  final int? startMinutes;
  final int? endMinutes;
  final RoutineType routineType;
  final int? notificationMinutes;

  String encode({required bool snooze}) =>
      '${snooze ? 'routine_snooze:' : 'routine_notification:'}${jsonEncode({
            'id': routineId,
            'weekday': weekday,
            'date': dateYmd,
            'version': updatedAtMs,
            'start': startMinutes,
            'end': endMinutes,
            'type': routineType.name,
            'notificationMinutes': notificationMinutes,
          })}';

  static RoutineNotificationTarget? parse(String? payload) {
    if (payload == null) return null;
    final snooze = payload.startsWith('routine_snooze:');
    if (!snooze && !payload.startsWith('routine_notification:')) return null;
    final value = payload.substring(payload.indexOf(':') + 1);
    if (!value.startsWith('{')) {
      // Existing delivered notifications remain navigable after an app update.
      final split = value.lastIndexOf(':');
      final id = snooze || split < 0 ? value : value.substring(0, split);
      return id.isEmpty ? null : RoutineNotificationTarget(routineId: id);
    }
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      final id = json['id'] as String;
      if (id.isEmpty) return null;
      return RoutineNotificationTarget(
        routineId: id,
        weekday: json['weekday'] as int?,
        dateYmd: json['date'] as String?,
        updatedAtMs: json['version'] as int?,
        startMinutes: json['start'] as int?,
        endMinutes: json['end'] as int?,
        routineType:
            json['type'] == 'sleep' ? RoutineType.sleep : RoutineType.activity,
        notificationMinutes: json['notificationMinutes'] as int?,
      );
    } catch (_) {
      return null;
    }
  }

  String? occurrenceDate(DateTime postedAt) {
    if (dateYmd != null) return dateYmd;
    if (weekday == null ||
        weekday! < 1 ||
        weekday! > 7 ||
        startMinutes == null) {
      return null;
    }
    var day = DateTime(postedAt.year, postedAt.month, postedAt.day);
    var daysBack = (postedAt.weekday - weekday!) % 7;
    if (daysBack == 0 &&
        postedAt.hour * 60 + postedAt.minute <
            (notificationMinutes ?? startMinutes!)) {
      daysBack = 7;
    }
    day = DateTime(day.year, day.month, day.day - daysBack);
    return TimeMinutes.dateYmd(day);
  }

  bool matches(Routine routine) =>
      routine.id == routineId &&
      routine.type == routineType &&
      routine.updatedAtMs == updatedAtMs &&
      routine.startMinutesFromMidnight == startMinutes &&
      routine.endMinutesFromMidnight == endMinutes;
}
