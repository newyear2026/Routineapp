import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:routine_notification_platform/routine_notification_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/routine_log.dart';
import '../../domain/models/routine_log_status.dart';
import '../../domain/utils/time_minutes.dart';
import '../repositories/routine_log_repository.dart';

class LocalRoutineLogRepository implements RoutineLogRepository {
  LocalRoutineLogRepository._();

  static final LocalRoutineLogRepository instance =
      LocalRoutineLogRepository._();

  static const _kLogs = 'domain.routine_logs.v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<List<RoutineLog>> loadAllLogs() async {
    final prefs = await _prefs;
    await prefs.reload();
    final raw = prefs.getString(_kLogs);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => RoutineLog.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<RoutineLog>> loadLogsForDate(DateTime dateLocal) async {
    final ymd = TimeMinutes.dateYmd(dateLocal);
    final all = await loadAllLogs();
    return all.where((l) => l.dateYmd == ymd).toList();
  }

  @override
  Future<void> upsertLog(RoutineLog log) async {
    if (await _nativeMutation('upsert', log: log) != null) return;
    final all = await loadAllLogs();
    final idx = all.indexWhere(
      (l) =>
          l.id == log.id ||
          (l.routineId == log.routineId && l.dateYmd == log.dateYmd),
    );
    if (idx >= 0) {
      all[idx] = log;
    } else {
      all.add(log);
    }
    final jsonStr = jsonEncode(all.map((e) => e.toJson()).toList());
    await (await _prefs).setString(_kLogs, jsonStr);
  }

  @override
  Future<void> deleteLogsForRoutine(String routineId) async {
    if (await _nativeMutation('delete', routineId: routineId) != null) return;
    final all = await loadAllLogs();
    all.removeWhere((log) => log.routineId == routineId);
    final jsonStr = jsonEncode(all.map((e) => e.toJson()).toList());
    await (await _prefs).setString(_kLogs, jsonStr);
  }

  @override
  Future<void> deleteLogForRoutineOnDate(
    String routineId,
    String dateYmd,
  ) async {
    if (await _nativeMutation('delete',
            routineId: routineId, dateYmd: dateYmd) !=
        null) {
      return;
    }
    final all = await loadAllLogs();
    all.removeWhere(
      (log) => log.routineId == routineId && log.dateYmd == dateYmd,
    );
    final jsonStr = jsonEncode(all.map((e) => e.toJson()).toList());
    await (await _prefs).setString(_kLogs, jsonStr);
  }

  /// A completion made by the app wins over an in-flight background snooze.
  @override
  Future<bool> saveNotificationSnooze(RoutineLog log) async {
    final result = await _nativeMutation('snooze', log: log);
    if (result != null) return result;
    final existing = await loadAllLogs();
    for (final old in existing) {
      if (old.routineId == log.routineId &&
          old.dateYmd == log.dateYmd &&
          (old.status == RoutineLogStatus.completed ||
              old.status == RoutineLogStatus.skipped ||
              (old.snoozedUntilMs ?? 0) >= (log.snoozedUntilMs ?? 0))) {
        return false;
      }
    }
    await upsertLog(log);
    return true;
  }

  Future<bool?> _nativeMutation(String operation,
      {RoutineLog? log, String? routineId, String? dateYmd}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      return await RoutineNotificationPlatform.mutateLogs(operation,
          log: log == null ? null : jsonEncode(log.toJson()),
          routineId: routineId,
          dateYmd: dateYmd);
    } on MissingPluginException {
      // Widget tests and render harnesses do not load Android plugins.
      if (kDebugMode) return null;
      rethrow;
    }
  }
}
