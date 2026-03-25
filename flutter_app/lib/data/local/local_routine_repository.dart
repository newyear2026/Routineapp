import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/routine.dart';
import '../repositories/routine_repository.dart';

/// SharedPreferences JSON — MVP (대용량 시 파일/DB로 교체)
class LocalRoutineRepository implements RoutineRepository {
  LocalRoutineRepository._();

  static final LocalRoutineRepository instance = LocalRoutineRepository._();

  static const _kRoutines = 'domain.routines.v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<List<Routine>> loadRoutines() async {
    final raw = (await _prefs).getString(_kRoutines);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Routine.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> saveRoutines(List<Routine> routines) async {
    final jsonStr = jsonEncode(routines.map((e) => e.toJson()).toList());
    await (await _prefs).setString(_kRoutines, jsonStr);
  }

  @override
  Future<void> addRoutine(Routine routine) async {
    final all = await loadRoutines();
    all.add(routine);
    await saveRoutines(all);
  }

  @override
  Future<void> upsertRoutine(Routine routine) async {
    final all = await loadRoutines();
    final idx = all.indexWhere((r) => r.id == routine.id);
    if (idx >= 0) {
      all[idx] = routine;
    } else {
      all.add(routine);
    }
    await saveRoutines(all);
  }
}
