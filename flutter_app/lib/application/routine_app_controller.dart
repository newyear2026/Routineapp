import 'package:flutter/material.dart';

import '../data/seed/routine_seed.dart';
import '../domain/models/routine.dart';
import '../domain/models/routine_log.dart';
import '../domain/services/routine_day_service.dart';
import '../domain/services/routine_log_action_service.dart';
import '../domain/services/routine_state_resolver.dart';
import '../domain/utils/time_minutes.dart';
import 'home/home_snapshot.dart';
import 'home/home_snapshot_builder.dart';
import 'services/routine_data_service.dart';

/// 앱 상태 — Home 은 [homeSnapshot] 만 사용
class RoutineAppController extends ChangeNotifier {
  RoutineAppController({
    RoutineDataService? dataService,
    RoutineDayService? dayService,
  })  : _data = dataService ?? RoutineDataService(),
        _dayService = dayService ?? const RoutineDayService();

  final RoutineDataService _data;
  final RoutineDayService _dayService;

  List<Routine> _routines = [];
  List<RoutineLog> _logsToday = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  DateTime get _now => DateTime.now();

  List<Routine> get _todaySorted =>
      _dayService.routinesForDate(_now, _routines);

  Routine? get _currentSlot =>
      _dayService.currentRoutineAt(_now, _todaySorted);

  HomeSnapshot get homeSnapshot => HomeSnapshotBuilder.build(
        nowLocal: _now,
        allRoutines: _routines,
        logsToday: _logsToday,
      );

  Future<void> load() async {
    _routines = await _data.loadRoutines();
    if (_routines.isEmpty) {
      _routines = RoutineSeed.defaultRoutines();
      await _data.saveRoutines(_routines);
    }
    _logsToday = await _data.loadLogsForDate(_now);
    _loaded = true;
    notifyListeners();
  }

  bool get canActOnCurrentSlot {
    final c = _currentSlot;
    if (c == null) return false;
    final log = _dayService.logForRoutine(c.id, _logsToday);
    return RoutineStateResolver.canApplyUserAction(
      routine: c,
      log: log,
      nowLocal: _now,
    );
  }

  Future<void> completeCurrent() async {
    await _applyForCurrentSlot(
      (routine, log, ymd) => RoutineLogActionService.complete(
        routine: routine,
        dateYmd: ymd,
        existing: log,
        nowLocal: _now,
      ),
    );
  }

  Future<void> snoozeCurrent() async {
    await _applyForCurrentSlot(
      (routine, log, ymd) => RoutineLogActionService.snooze(
        routine: routine,
        dateYmd: ymd,
        existing: log,
        nowLocal: _now,
      ),
    );
  }

  Future<void> skipCurrent() async {
    await _applyForCurrentSlot(
      (routine, log, ymd) => RoutineLogActionService.skip(
        routine: routine,
        dateYmd: ymd,
        existing: log,
        nowLocal: _now,
      ),
    );
  }

  Future<void> _applyForCurrentSlot(
    RoutineLogApplyOutcome Function(
      Routine routine,
      RoutineLog? log,
      String ymd,
    ) action,
  ) async {
    final c = _currentSlot;
    if (c == null) return;
    final ymd = TimeMinutes.dateYmd(_now);
    final log = _dayService.logForRoutine(c.id, _logsToday);
    final outcome = action(c, log, ymd);
    if (!outcome.shouldPersist) return;
    await _data.upsertLog(outcome.log);
    _logsToday = await _data.loadLogsForDate(_now);
    notifyListeners();
  }
}
