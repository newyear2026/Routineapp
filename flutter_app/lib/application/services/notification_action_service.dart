import '../../data/local/local_routine_log_repository.dart';
import '../../data/local/local_routine_repository.dart';
import '../../data/local/local_settings_repository.dart';
import '../../data/repositories/routine_log_repository.dart';
import '../../data/repositories/routine_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/models/routine_action_source.dart';
import '../../domain/models/routine_notification_target.dart';
import '../../domain/models/routine_log_status.dart';
import '../../domain/services/routine_log_action_service.dart';
import '../../domain/settings/notification_permission_status.dart';
import '../../domain/utils/time_minutes.dart';
import '../../l10n/app_localizations.dart';
import 'routine_notification_service.dart';

/// Handles a specific delivered occurrence, never the controller's current slot.
class NotificationActionService {
  NotificationActionService({
    RoutineRepository? routines,
    RoutineLogRepository? logs,
    SettingsRepository? settings,
    RoutineNotificationService? notifications,
  })  : _routines = routines ?? LocalRoutineRepository.instance,
        _logs = logs ?? LocalRoutineLogRepository.instance,
        _settings = settings ?? LocalSettingsRepository.instance,
        _notifications = notifications ?? RoutineNotificationService();

  final RoutineRepository _routines;
  final RoutineLogRepository _logs;
  final SettingsRepository _settings;
  final RoutineNotificationService _notifications;

  Future<bool> snooze({
    required RoutineNotificationTarget target,
    required DateTime postedAt,
    required DateTime now,
    required AppLocalizations l10n,
  }) async {
    final date = target.occurrenceDate(postedAt);
    if (date != TimeMinutes.dateYmd(now) || postedAt.isAfter(now)) return false;
    final routines = await _routines.loadRoutines();
    final matches = routines.where((r) => r.id == target.routineId);
    if (matches.isEmpty) return false;
    final routine = matches.first;
    final minute = now.hour * 60 + now.minute;
    if (!target.matches(routine) ||
        !routine.notificationEnabled ||
        !routine.repeatWeekdays.contains(now.weekday) ||
        minute < routine.startMinutesFromMidnight ||
        minute >= routine.endMinutesFromMidnight) {
      return false;
    }
    final preferences = await _settings.loadNotificationPreferences();
    if (!preferences.notificationsEnabled ||
        preferences.permissionStatus != NotificationPermissionStatus.granted) {
      return false;
    }
    final logs = await _logs.loadLogsForDate(now);
    final existing = logs.where((l) => l.routineId == routine.id).firstOrNull;
    final outcome = RoutineLogActionService.snooze(
      routine: routine,
      dateYmd: date!,
      existing: existing,
      nowLocal: now,
      source: RoutineActionSource.notification,
    );
    if (!outcome.shouldPersist ||
        !await _logs.saveNotificationSnooze(outcome.log)) {
      return false;
    }
    await _notifications.scheduleSnooze(routine,
        DateTime.fromMillisecondsSinceEpoch(outcome.log.snoozedUntilMs!), l10n,
        occurrenceDate: date);
    // Completion/deletion may have raced the asynchronous schedule operation.
    final latest = await _logs.loadLogsForDate(now);
    final log = latest.where((l) => l.routineId == routine.id).firstOrNull;
    final stillExists = (await _routines.loadRoutines())
        .any((r) => target.matches(r) && r.notificationEnabled);
    if (!stillExists || log?.status != RoutineLogStatus.snoozed) {
      await _notifications.cancelSnooze(routine.id);
    }
    return true;
  }
}
