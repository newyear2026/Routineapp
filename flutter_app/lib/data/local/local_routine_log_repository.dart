import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/routine_log.dart';
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
    final raw = (await _prefs).getString(_kLogs);
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
    final all = await loadAllLogs();
    final idx = all.indexWhere((l) => l.id == log.id);
    if (idx >= 0) {
      all[idx] = log;
    } else {
      all.add(log);
    }
    final jsonStr = jsonEncode(all.map((e) => e.toJson()).toList());
    await (await _prefs).setString(_kLogs, jsonStr);
  }
}
