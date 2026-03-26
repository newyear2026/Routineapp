import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../domain/models/routine.dart';
import '../domain/models/routine_log.dart';
import '../domain/models/routine_action_source.dart';
import '../domain/services/routine_day_service.dart';
import '../domain/services/routine_log_action_service.dart';
import '../domain/services/routine_state_resolver.dart';
import '../domain/utils/time_minutes.dart';
import 'home/home_snapshot.dart';
import 'home/home_snapshot_builder.dart';
import 'home/progress_summary.dart';
import 'routine_save_result.dart';
import 'services/routine_data_service.dart';
import '../widget_home/home_widget_sync_service.dart';

/// 앱 MVP 상태 — Repository는 [RoutineDataService], Home은 [homeSnapshot] / 슬롯·진행 요약 getter
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

  /// 충돌 검사·편집 로드용 — 저장 후 [load]로 갱신됨
  List<Routine> get routines => List<Routine>.unmodifiable(_routines);

  DateTime get _now => DateTime.now();

  /// Progress — 오늘 요일 스케줄 루틴
  List<Routine> get todayScheduledRoutines =>
      _dayService.routinesForDate(_now, _routines);

  List<RoutineLog> get todayLogs => List<RoutineLog>.unmodifiable(_logsToday);

  List<Routine> get _todaySorted =>
      _dayService.routinesForDate(_now, _routines);

  Routine? get _currentSlot =>
      _dayService.currentRoutineAt(_now, _todaySorted);

  HomeSnapshot get homeSnapshot => HomeSnapshotBuilder.build(
        nowLocal: _now,
        allRoutines: _routines,
        logsToday: _logsToday,
      );

  /// 위젯 확장용 — [homeSnapshot]과 동일 도메인 루틴
  Routine? get currentRoutine => homeSnapshot.currentRoutine;

  Routine? get nextRoutine => homeSnapshot.nextRoutine;

  /// [calculateProgress] 기준 진행 요약
  ProgressSummary get progressSummary => homeSnapshot.progressSummary;

  /// 로컬 저장소에서 루틴·오늘 로그 로드 (Home 진입·저장 후 등)
  Future<void> load() async {
    _routines = await _data.loadRoutines();
    _logsToday = await _data.loadLogsForDate(_now);
    _loaded = true;
    notifyListeners();
    if (!kIsWeb) {
      await HomeWidgetSyncService.instance.push(homeSnapshot);
    }
  }

  /// 신규·수정 저장 — [updatedAtMs]는 항상 저장 시각으로 갱신
  Future<RoutineSaveResult> saveRoutine(Routine routine) async {
    final toSave = routine.copyWith(
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    try {
      await _data.upsertRoutine(toSave);
      await load();
      return RoutineSaveResult.success;
    } catch (e, st) {
      debugPrint('saveRoutine failed: $e\n$st');
      return RoutineSaveResult.failure(
        '저장에 실패했어요. 잠시 후 다시 시도해 주세요.',
      );
    }
  }

  /// 하위 호환 — [saveRoutine]과 동일
  Future<RoutineSaveResult> addRoutine(Routine routine) => saveRoutine(routine);

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
        source: RoutineActionSource.app,
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
        source: RoutineActionSource.app,
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
        source: RoutineActionSource.app,
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
    if (!kIsWeb) {
      await HomeWidgetSyncService.instance.push(homeSnapshot);
    }
  }
}
