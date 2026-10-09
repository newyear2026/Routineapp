import 'package:flutter/foundation.dart';

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
import '../../domain/services/routine_occurrences.dart';
import '../../domain/services/routine_state_resolver.dart';
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

  Future<bool> complete({
    required RoutineNotificationTarget target,
    required DateTime postedAt,
    required DateTime now,
  }) async {
    final date = target.occurrenceDate(postedAt);
    if (date == null || postedAt.isAfter(now)) return false;
    final anchor = DateTime.tryParse(date);
    if (anchor == null) return false;
    final matches = (await _routines.loadRoutines())
        .where((routine) => routine.id == target.routineId);
    if (matches.isEmpty) return false;
    final routine = RoutineOccurrences.onDate(matches.first, anchor);
    if (!target.matches(routine) ||
        !routine.wakeAlarmActive ||
        !routine.repeatWeekdays.contains(anchor.weekday)) {
      return false;
    }
    final logs = await _logs.loadLogsForDate(anchor);
    final existing =
        logs.where((log) => log.routineId == routine.id).firstOrNull;
    if (!RoutineStateResolver.canApplyUserAction(
        routine: routine, log: existing, nowLocal: now)) {
      return false;
    }
    final outcome = RoutineLogActionService.complete(
      routine: routine,
      dateYmd: date,
      existing: existing,
      nowLocal: now,
      source: RoutineActionSource.notification,
    );
    if (!outcome.shouldPersist) return false;
    final saved = await _logs.saveWidgetCompletion(outcome.log);
    if (!saved) return false;
    // 완료는 이미 저장됐다. 재알림을 거두다 실패했다고 완료까지 없던 일로
    // 돌리면 위젯 갱신도 건너뛰게 된다.
    try {
      await _notifications.cancelSnooze(routine.id);
    } catch (e, st) {
      debugPrint('wake snooze cancel failed: $e\n$st');
    }
    return true;
  }

  Future<bool> snooze({
    required RoutineNotificationTarget target,
    required DateTime postedAt,
    required DateTime now,
    required AppLocalizations l10n,
  }) async {
    final date = target.occurrenceDate(postedAt);
    if (date == null || postedAt.isAfter(now)) return false;
    final anchor = DateTime.tryParse(date);
    if (anchor == null) return false;
    final routines = await _routines.loadRoutines();
    final matches = routines.where((r) => r.id == target.routineId);
    if (matches.isEmpty) return false;
    final routine = RoutineOccurrences.onDate(matches.first, anchor);
    if (!target.matches(routine) ||
        !routine.alertsEnabled ||
        !routine.repeatWeekdays.contains(anchor.weekday) ||
        !RoutineStateResolver.canApplyUserAction(
            routine: routine, log: null, nowLocal: now)) {
      return false;
    }
    final preferences = await _settings.loadNotificationPreferences();
    if (!preferences.notificationsEnabled ||
        preferences.permissionStatus != NotificationPermissionStatus.granted) {
      return false;
    }
    final logs = await _logs.loadLogsForDate(anchor);
    final existing = logs.where((l) => l.routineId == routine.id).firstOrNull;
    final outcome = RoutineLogActionService.snooze(
      routine: routine,
      dateYmd: date,
      existing: existing,
      nowLocal: now,
      delay: routine.wakeAlarmActive
          ? RoutineLogActionService.wakeAlarmSnooze
          : RoutineLogActionService.defaultSnooze,
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
    final latest = await _logs.loadLogsForDate(anchor);
    final log = latest.where((l) => l.routineId == routine.id).firstOrNull;
    final stillExists = (await _routines.loadRoutines())
        .any((r) => target.matches(r) && r.alertsEnabled);
    if (!stillExists || log?.status != RoutineLogStatus.snoozed) {
      await _notifications.cancelSnooze(routine.id);
    }
    return true;
  }
}
