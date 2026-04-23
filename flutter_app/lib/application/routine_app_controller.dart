import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';

import '../data/local/local_settings_repository.dart';
import '../domain/models/routine.dart';
import '../domain/models/routine_log.dart';
import '../domain/models/routine_action_source.dart';
import '../domain/models/app_settings.dart';
import '../domain/services/routine_day_service.dart';
import '../domain/services/routine_log_action_service.dart';
import '../domain/services/routine_state_resolver.dart';
import '../domain/utils/time_minutes.dart';
import '../theme/app_theme_preset.dart';
import 'home/home_snapshot.dart';
import 'home/home_snapshot_builder.dart';
import 'home/progress_summary.dart';
import 'routine_save_result.dart';
import 'services/routine_notification_service.dart';
import 'services/routine_data_service.dart';
import '../widget_home/home_widget_sync_service.dart';

/// 앱 MVP 상태 — Repository는 [RoutineDataService], Home은 [homeSnapshot] / 슬롯·진행 요약 getter
class RoutineAppController extends ChangeNotifier {
  RoutineAppController({
    RoutineDataService? dataService,
    RoutineDayService? dayService,
    RoutineNotificationService? notificationService,
    DateTime Function()? nowProvider,
    bool clockAutoRefreshEnabled = true,
  })  : _data = dataService ?? RoutineDataService(),
        _dayService = dayService ?? const RoutineDayService(),
        _notifications = notificationService ?? RoutineNotificationService(),
        _nowProvider = nowProvider ?? DateTime.now,
        _clockAutoRefreshEnabled = clockAutoRefreshEnabled;

  final RoutineDataService _data;
  final RoutineDayService _dayService;
  final RoutineNotificationService _notifications;
  final LocalSettingsRepository _settings = LocalSettingsRepository.instance;
  final DateTime Function() _nowProvider;
  final bool _clockAutoRefreshEnabled;

  List<Routine> _routines = [];
  List<RoutineLog> _logsToday = [];
  AppSettings _appSettings = const AppSettings();
  bool _loaded = false;
  String? _loadedDateYmd;
  DateTime? _loadedAt;
  Timer? _clockTimer;
  bool _clockRefreshInFlight = false;

  bool get isLoaded => _loaded;

  /// 충돌 검사·편집 로드용 — 저장 후 [load]로 갱신됨
  List<Routine> get routines => List<Routine>.unmodifiable(_routines);
  AppSettings get appSettings => _appSettings;
  String get themeId => _appSettings.themeId ?? AppThemePreset.softDay.id;
  AppThemePreset get currentThemePreset => AppThemePreset.byId(themeId);

  DateTime get _now => _nowProvider();

  /// Progress — 오늘 요일 스케줄 루틴
  List<Routine> get todayScheduledRoutines =>
      _dayService.routinesForDate(_now, _routines);

  List<RoutineLog> get todayLogs => List<RoutineLog>.unmodifiable(_logsToday);

  List<Routine> get _todaySorted =>
      _dayService.routinesForDate(_now, _routines);

  Routine? get _currentSlot => _dayService.currentRoutineAt(_now, _todaySorted);

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
    final now = _now;
    _routines = await _data.loadRoutines();
    _logsToday = await _data.loadLogsForDate(now);
    _appSettings = await _settings.loadAppSettings();
    _loadedDateYmd = TimeMinutes.dateYmd(now);
    _loadedAt = now;
    _loaded = true;
    if (_clockAutoRefreshEnabled) {
      _scheduleNextClockTick();
    }
    notifyListeners();
    if (!kIsWeb) {
      await HomeWidgetSyncService.instance.push(homeSnapshot);
      await _notifications.syncAll(_routines);
    }
  }

  /// 화면 복귀 시 과도한 재로드를 막기 위한 경량 리로드
  Future<void> reloadOnReturn({Duration minInterval = const Duration(seconds: 2)}) async {
    final now = _now;
    if (_loadedAt != null && now.difference(_loadedAt!) < minInterval) {
      return;
    }
    await load();
  }

  Future<void> updateTheme(String themeId) async {
    _appSettings = _appSettings.copyWith(themeId: themeId);
    await _settings.saveAppSettings(_appSettings);
    notifyListeners();
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

  Future<RoutineSaveResult> deleteRoutine(String routineId) async {
    try {
      await _data.deleteRoutine(routineId);
      await load();
      return RoutineSaveResult.success;
    } catch (e, st) {
      debugPrint('deleteRoutine failed: $e\n$st');
      return RoutineSaveResult.failure(
        '삭제에 실패했어요. 잠시 후 다시 시도해 주세요.',
      );
    }
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

  void _scheduleNextClockTick() {
    _clockTimer?.cancel();
    if (!_loaded) return;

    final now = _now;
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    _clockTimer = Timer(nextMinute.difference(now), _handleClockTimerFired);
  }

  void _handleClockTimerFired() {
    _refreshClockState();
  }

  Future<void> _refreshClockState() async {
    if (_clockRefreshInFlight || !_loaded) {
      _scheduleNextClockTick();
      return;
    }

    _clockRefreshInFlight = true;
    try {
      final now = _now;
      final currentYmd = TimeMinutes.dateYmd(now);
      if (_loadedDateYmd != currentYmd) {
        _logsToday = await _data.loadLogsForDate(now);
        _loadedDateYmd = currentYmd;
      }

      notifyListeners();
      if (!kIsWeb) {
        await HomeWidgetSyncService.instance.push(homeSnapshot);
      }
    } finally {
      _clockRefreshInFlight = false;
      _scheduleNextClockTick();
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @visibleForTesting
  Future<void> refreshClockStateForTest() => _refreshClockState();
}
