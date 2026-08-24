import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';

import '../data/local/local_settings_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../domain/models/routine.dart';
import '../domain/models/routine_log.dart';
import '../domain/models/routine_action_source.dart';
import '../domain/models/routine_write_error.dart';
import '../domain/models/app_settings.dart';
import '../domain/settings/app_language.dart';
import '../l10n/app_localizations.dart';
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

/// 앱 MVP 상태 — Repository는 [RoutineDataService], Home은 [homeSnapshotFor] / 슬롯·진행 요약 getter
class RoutineAppController extends ChangeNotifier {
  RoutineAppController({
    RoutineDataService? dataService,
    RoutineDayService? dayService,
    RoutineNotificationService? notificationService,
    SettingsRepository? settingsRepository,
    DateTime Function()? nowProvider,
    bool clockAutoRefreshEnabled = true,
  })  : _data = dataService ?? RoutineDataService(),
        _dayService = dayService ?? const RoutineDayService(),
        _notifications = notificationService ?? RoutineNotificationService(),
        _settings = settingsRepository ?? LocalSettingsRepository.instance,
        _nowProvider = nowProvider ?? DateTime.now,
        _clockAutoRefreshEnabled = clockAutoRefreshEnabled;

  final RoutineDataService _data;
  final RoutineDayService _dayService;
  final RoutineNotificationService _notifications;
  final SettingsRepository _settings;
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

  /// 사용자가 설정에서 고른 언어. [AppLanguage.system]이면 기기 언어를 따른다.
  AppLanguage get language => AppLanguage.fromCode(_appSettings.localeCode);

  /// `MaterialApp.locale`에 그대로 넘긴다. null이면 Flutter가 기기 언어로 고른다.
  Locale? get locale => language.locale;

  /// 실제로 화면에 쓰이는 로케일.
  ///
  /// 설정에서 고른 언어가 없으면 기기 언어를 지원 목록과 맞춰보고, 맞는 것이
  /// 없으면 [AppLanguage.fallback]으로 내린다. 홈 스냅샷과 홈 위젯 동기화는
  /// BuildContext 없이 문자열을 만들어야 해서 여기서 한 번 정한다.
  Locale get resolvedLocale {
    final chosen = language.locale;
    if (chosen != null) return chosen;

    final deviceLanguage =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    for (final supported in AppLanguage.supportedLocales) {
      if (supported.languageCode == deviceLanguage) return supported;
    }
    return Locale(AppLanguage.fallback.code!);
  }

  /// BuildContext 없이 쓰는 현재 언어의 문자열.
  AppLocalizations get strings => lookupAppLocalizations(resolvedLocale);

  DateTime get _now => _nowProvider();

  /// 모든 화면이 같은 날짜·시간을 표시하도록 제공하는 앱 기준 시각.
  DateTime get now => _now;

  /// Progress — 오늘 요일 스케줄 루틴
  List<Routine> get todayScheduledRoutines =>
      _dayService.routinesForDate(_now, _routines);

  List<RoutineLog> get todayLogs => List<RoutineLog>.unmodifiable(_logsToday);

  List<Routine> get _todaySorted =>
      _dayService.routinesForDate(_now, _routines);

  Routine? get _currentSlot => _dayService.currentRoutineAt(_now, _todaySorted);

  /// 화면이 그리는 스냅샷 — **화면 자신의 [AppLocalizations]로 만든다.**
  ///
  /// 컨트롤러가 로케일을 따로 해석해 문자열을 만들면, 위젯 트리가 그리는
  /// 언어와 어긋날 수 있다(테스트처럼 트리 로케일을 지정한 경우가 그렇다).
  /// 화면에 보이는 말은 화면의 언어를 따른다.
  HomeSnapshot homeSnapshotFor(AppLocalizations l10n) =>
      HomeSnapshotBuilder.build(
        l10n: l10n,
        nowLocal: _now,
        allRoutines: _routines,
        logsToday: _logsToday,
      );

  /// 위젯 트리 밖(홈 위젯 동기화·알림)에서 쓰는 스냅샷.
  ///
  /// 이쪽은 BuildContext가 없으므로 [strings]가 정한 언어를 쓴다.
  HomeSnapshot get _snapshotForBackground => homeSnapshotFor(strings);

  /// 위젯 확장용 — 화면 스냅샷과 동일 도메인 루틴
  Routine? get currentRoutine => _snapshotForBackground.currentRoutine;

  Routine? get nextRoutine => _snapshotForBackground.nextRoutine;

  /// [calculateProgress] 기준 진행 요약
  ProgressSummary get progressSummary =>
      _snapshotForBackground.progressSummary;

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
    await _syncSideEffects();
  }

  /// 홈 위젯·알림 동기화는 **부수 효과**다. 여기서 터져도 로드나 저장이
  /// 실패한 것은 아니다.
  ///
  /// 예전에는 이 둘을 [load] 본문에서 그대로 await 해서, 알림 플러그인이
  /// 예외를 던지면 [saveRoutine]의 catch까지 올라가 "저장에 실패했어요"가
  /// 떴다. 실제로는 이미 저장된 뒤라, 사용자가 다시 눌러 같은 루틴을
  /// 여러 개 만들었다.
  Future<void> _syncSideEffects() async {
    if (kIsWeb) return;
    try {
      await HomeWidgetSyncService.instance.push(_snapshotForBackground, strings);
    } catch (e, st) {
      debugPrint('home widget sync failed: $e\n$st');
    }
    try {
      await _notifications.syncAll(_routines, strings);
    } catch (e, st) {
      debugPrint('notification sync failed: $e\n$st');
    }
  }

  /// 화면 복귀 시 과도한 재로드를 막기 위한 경량 리로드
  Future<void> reloadOnReturn(
      {Duration minInterval = const Duration(seconds: 2)}) async {
    final now = _now;
    if (_loadedAt != null && now.difference(_loadedAt!) < minInterval) {
      return;
    }
    await load();
  }

  Future<void> updateLanguage(AppLanguage language) async {
    _appSettings = _appSettings.copyWith(
      localeCode: language.code,
      clearLocaleCode: language == AppLanguage.system,
    );
    await _settings.saveAppSettings(_appSettings);
    notifyListeners();
  }

  Future<void> updateTheme(String themeId) async {
    _appSettings = _appSettings.copyWith(themeId: themeId);
    await _settings.saveAppSettings(_appSettings);
    notifyListeners();
  }

  /// 신규·수정 저장 — [updatedAtMs]는 항상 저장 시각으로 갱신
  ///
  /// 실패로 보고하는 것은 **쓰기가 실패했을 때뿐**이다. 쓰기가 끝난 뒤의
  /// 재로드·동기화가 실패해도 데이터는 이미 남아 있으므로 성공으로 답한다.
  /// 여기서 실패라고 말하면 사용자가 다시 눌러 중복을 만든다.
  Future<RoutineSaveResult> saveRoutine(Routine routine) async {
    final toSave = routine.copyWith(
      updatedAtMs: _now.millisecondsSinceEpoch,
    );
    try {
      await _data.upsertRoutine(toSave);
    } catch (e, st) {
      debugPrint('saveRoutine write failed: $e\n$st');
      return RoutineSaveResult.failure(RoutineWriteError.save);
    }
    await _reloadAfterWrite();
    return RoutineSaveResult.success;
  }

  /// 쓰기 뒤 재로드. 실패해도 호출자에게 오류로 올리지 않는다.
  Future<void> _reloadAfterWrite() async {
    try {
      await load();
    } catch (e, st) {
      debugPrint('reload after write failed: $e\n$st');
    }
  }

  /// 하위 호환 — [saveRoutine]과 동일
  Future<RoutineSaveResult> addRoutine(Routine routine) => saveRoutine(routine);

  Future<RoutineSaveResult> deleteRoutine(String routineId) async {
    try {
      await _data.deleteRoutine(routineId);
    } catch (e, st) {
      debugPrint('deleteRoutine write failed: $e\n$st');
      return RoutineSaveResult.failure(RoutineWriteError.delete);
    }
    await _reloadAfterWrite();
    return RoutineSaveResult.success;
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

  Future<RoutineActionUndo?> completeCurrent() => _applyForCurrentSlot(
        (routine, log, ymd) => RoutineLogActionService.complete(
          routine: routine,
          dateYmd: ymd,
          existing: log,
          nowLocal: _now,
          source: RoutineActionSource.app,
        ),
      );

  Future<RoutineActionUndo?> snoozeCurrent() => _applyForCurrentSlot(
        (routine, log, ymd) => RoutineLogActionService.snooze(
          routine: routine,
          dateYmd: ymd,
          existing: log,
          nowLocal: _now,
          source: RoutineActionSource.app,
        ),
      );

  Future<RoutineActionUndo?> skipCurrent() => _applyForCurrentSlot(
        (routine, log, ymd) => RoutineLogActionService.skip(
          routine: routine,
          dateYmd: ymd,
          existing: log,
          nowLocal: _now,
          source: RoutineActionSource.app,
        ),
      );

  Future<RoutineActionUndo?> _applyForCurrentSlot(
    RoutineLogApplyOutcome Function(
      Routine routine,
      RoutineLog? log,
      String ymd,
    ) action,
  ) async {
    final c = _currentSlot;
    if (c == null) return null;
    final ymd = TimeMinutes.dateYmd(_now);
    final log = _dayService.logForRoutine(c.id, _logsToday);
    final outcome = action(c, log, ymd);
    if (!outcome.shouldPersist) return null;
    await _data.upsertLog(outcome.log);
    _logsToday = await _data.loadLogsForDate(_now);
    notifyListeners();
    if (!kIsWeb) {
      await HomeWidgetSyncService.instance.push(_snapshotForBackground, strings);
    }
    return RoutineActionUndo(
      routineId: c.id,
      dateYmd: ymd,
      previousLog: log,
    );
  }

  /// 바로 직전에 기록한 완료·미루기·스킵 동작을 되돌린다.
  Future<void> undoAction(RoutineActionUndo undo) async {
    if (undo.previousLog == null) {
      await _data.deleteLogForRoutineOnDate(undo.routineId, undo.dateYmd);
    } else {
      await _data.upsertLog(undo.previousLog!);
    }
    _logsToday = await _data.loadLogsForDate(_now);
    notifyListeners();
    if (!kIsWeb) {
      await HomeWidgetSyncService.instance.push(_snapshotForBackground, strings);
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
        await HomeWidgetSyncService.instance.push(_snapshotForBackground, strings);
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

class RoutineActionUndo {
  const RoutineActionUndo({
    required this.routineId,
    required this.dateYmd,
    required this.previousLog,
  });

  final String routineId;
  final String dateYmd;
  final RoutineLog? previousLog;
}
