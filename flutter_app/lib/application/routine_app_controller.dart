import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';

import '../data/local/local_settings_repository.dart';
import '../data/local/pack_trial_storage.dart';
import '../data/repositories/settings_repository.dart';
import '../data/store/character_pack_catalog.dart';
import '../domain/ads/ad_slot.dart';
import '../domain/models/routine.dart';
import '../domain/models/routine_log.dart';
import '../domain/models/routine_log_status.dart';
import '../domain/models/routine_action_source.dart';
import '../domain/models/routine_write_error.dart';
import '../domain/models/app_settings.dart';
import '../domain/settings/app_language.dart';
import '../domain/store/character_pack.dart';
import '../domain/store/pack_trial.dart';
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
import 'services/ad_config.dart';
import 'services/exact_alarm_service.dart';
import 'services/rewarded_ad_service.dart';
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
    CharacterPackOwnership packOwnership = const BundledOnlyOwnership(),
    PackTrialStore packTrialStore = const LocalPackTrialStore(),
    bool? rewardedPackTrials,
    Future<RewardedAdOutcome> Function(AdSlot slot)? showRewardedAd,
    @visibleForTesting
    List<CharacterPack> characterPacks = CharacterPackCatalog.all,
    DateTime Function()? nowProvider,
    bool clockAutoRefreshEnabled = true,
  })  : _data = dataService ?? RoutineDataService(),
        _dayService = dayService ?? const RoutineDayService(),
        _notifications = notificationService ?? RoutineNotificationService(),
        _settings = settingsRepository ?? LocalSettingsRepository.instance,
        _basePackOwnership = packOwnership,
        _packTrialStore = packTrialStore,
        _rewardedPackTrials =
            rewardedPackTrials ?? (!kIsWeb && AdConfig.isPlatformSupported),
        _showRewardedAd = showRewardedAd ?? RewardedAdService.instance.show,
        _characterPacks = characterPacks,
        _nowProvider = nowProvider ?? DateTime.now,
        _clockAutoRefreshEnabled = clockAutoRefreshEnabled;

  final RoutineDataService _data;
  final RoutineDayService _dayService;
  final RoutineNotificationService _notifications;
  final SettingsRepository _settings;
  final CharacterPackOwnership _basePackOwnership;
  final PackTrialStore _packTrialStore;
  final bool _rewardedPackTrials;
  final Future<RewardedAdOutcome> Function(AdSlot slot) _showRewardedAd;

  /// 체험이 바뀔 때만 새로 만든다. 스코프는 이 객체가 바뀌었는지로 팩 화면을
  /// 다시 그릴지 정하므로, 매번 새로 만들면 시계가 갈 때마다 전부 다시 그린다.
  late RewardedTrialOwnership _packOwnership = _buildPackOwnership(const {});
  Map<String, DateTime> _packTrialEnds = const {};
  final List<CharacterPack> _characterPacks;
  final DateTime Function() _nowProvider;
  final bool _clockAutoRefreshEnabled;

  List<Routine> _routines = [];
  List<RoutineLog> _logsToday = [];
  AppSettings _appSettings = const AppSettings();
  bool _loaded = false;
  bool _loadFailed = false;
  String? _loadedDateYmd;
  DateTime? _loadedAt;
  Timer? _clockTimer;
  bool _clockRefreshInFlight = false;

  bool get isLoaded => _loaded;

  /// 로드가 실패해 **보여 줄 것이 아무것도 없는** 상태.
  ///
  /// 저장 뒤 다시 부른 로드가 실패한 경우는 여기 들어오지 않는다. 그때는
  /// 이미 화면에 있는(조금 낡은) 데이터를 계속 보여 주는 편이 낫다.
  bool get hasBlockingLoadError => _loadFailed && !_loaded;

  /// 충돌 검사·편집 로드용 — 저장 후 [load]로 갱신됨
  List<Routine> get routines => List<Routine>.unmodifiable(_routines);
  AppSettings get appSettings => _appSettings;
  String get themeId => _appSettings.themeId ?? AppThemePreset.softDay.id;
  AppThemePreset get currentThemePreset =>
      currentPack.id == CharacterPackCatalog.poodleGarden.id
          ? AppThemePreset.poodleGarden
          : AppThemePreset.byId(themeId);

  /// 팩 소유 판정 — 구매 판정에 광고 체험을 얹은 것.
  ///
  /// 결제가 붙으면 구매 저장소가 생성자의 `packOwnership` 자리에 들어온다.
  CharacterPackOwnership get packOwnership => _packOwnership;

  /// [pack]을 광고로 체험 중이면 끝나는 시각.
  DateTime? packTrialEndsAt(CharacterPack pack) =>
      _packOwnership.trialEndsAt(pack);

  RewardedTrialOwnership _buildPackOwnership(Map<String, DateTime> ends) =>
      RewardedTrialOwnership(
        base: _basePackOwnership,
        trialEnds: ends,
        rewardedAdsAvailable: _rewardedPackTrials,
        now: () => _now,
      );

  void _setPackTrialEnds(Map<String, DateTime> ends) {
    _packTrialEnds = Map.unmodifiable(ends);
    _packOwnership = _buildPackOwnership(_packTrialEnds);
  }

  /// 앱이 지금 그리는 캐릭터 팩 — 저장값이 아니라 판정 결과다.
  CharacterPack get currentPack => CharacterPackCatalog.resolve(
        _appSettings.characterPackId,
        _packOwnership,
        packs: _characterPacks,
      );

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
  ProgressSummary get progressSummary => _snapshotForBackground.progressSummary;

  /// 로컬 저장소에서 루틴·오늘 로그 로드 (Home 진입·저장 후 등)
  ///
  /// 실패해도 **던지지 않는다.** 저장된 JSON 이 깨지면 `jsonDecode` 가
  /// 그대로 터지는데, 예전에는 이 예외가 `main` 의 `..load()` 밖으로 나가
  /// 아무도 받지 않았다. [_loaded] 는 false 에 머물고 화면은 돌아가는
  /// 동그라미에서 영영 멈췄다 — 오류도, 다시 시도할 길도 없었다.
  ///
  /// 실패해도 저장소에는 쓰지 않는다. 깨진 데이터라도 원본이 남아 있어야
  /// 나중에 손볼 수 있다. 빈 값으로 덮어쓰면 그 길이 사라진다.
  Future<void> load() async {
    final now = _now;

    // 셋 다 성공한 뒤에 옮겨 담는다. 중간에 터졌을 때 반쯤 갱신된 상태가
    // 남으면, 다시 시도하기 전까지 화면이 앞뒤 안 맞는 값을 보여 준다.
    final List<Routine> routines;
    final List<RoutineLog> logs;
    final AppSettings settings;
    try {
      routines = await _data.loadRoutines();
      logs = await _data.loadLogsForDate(now);
      settings = await _settings.loadAppSettings();
    } catch (e, st) {
      debugPrint('initial load failed: $e\n$st');
      _loadFailed = true;
      notifyListeners();
      return;
    }

    _routines = routines;
    _logsToday = logs;
    _appSettings = settings;
    _setPackTrialEnds(await _loadPackTrialEnds());
    _loadFailed = false;
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
    await _pushHomeWidget();
    try {
      await _notifications.syncAll(_routines, strings);
    } catch (e, st) {
      debugPrint('notification sync failed: $e\n$st');
    }
  }

  /// 홈 위젯 갱신 — 실패해도 여기서 삼킨다.
  ///
  /// 기록은 이미 저장소에 들어간 뒤에 부르는 것이다. 위젯 갱신이 터졌다고
  /// 호출자까지 실패로 끌고 가면, 저장은 끝났는데 홈에는 성공 안내도
  /// 되돌리기 버튼도 나오지 않는다. [_syncSideEffects]가 로드·저장 경로에서
  /// 하던 구분을 완료·미루기·스킵·되돌리기 경로에도 똑같이 적용한다.
  Future<void> _pushHomeWidget() async {
    if (kIsWeb) return;
    try {
      await HomeWidgetSyncService.instance
          .push(_snapshotForBackground, strings);
    } catch (e, st) {
      debugPrint('home widget sync failed: $e\n$st');
    }
  }

  /// 마지막으로 알림을 걸 때의 정확 알람 권한. 앱 밖(시스템 설정)에서 바뀌므로
  /// 복귀할 때마다 대조한다.
  bool? _exactAlarmsAtLastSync;

  /// 앱이 화면에 돌아왔을 때 정확 알람 권한이 달라졌으면 알림을 다시 건다.
  ///
  /// 이 권한은 시스템 설정에서만 바뀌고, 이미 예약된 알람은 예약 시점의
  /// 정확/부정확 모드를 그대로 들고 있다. 다시 걸지 않으면 사용자가 권한을
  /// 켜도 그날의 알림은 계속 늦게 온다.
  Future<void> resyncIfExactAlarmPermissionChanged() async {
    if (kIsWeb) return;
    final allowed = await ExactAlarmService.instance.canScheduleExactAlarms();
    if (allowed == _exactAlarmsAtLastSync) return;
    _exactAlarmsAtLastSync = allowed;
    await resyncNotifications();
  }

  /// 알림만 다시 예약한다. 정확 알람 권한처럼 앱 밖에서 바뀌는 조건은
  /// 이미 예약된 알람에 반영되지 않으므로, 바뀐 뒤 다시 걸어야 한다.
  Future<void> resyncNotifications() async {
    if (kIsWeb) return;
    try {
      await _notifications.syncAll(_routines, strings);
    } catch (e, st) {
      debugPrint('notification resync failed: $e\n$st');
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
    if (language == this.language) return;

    final previousLocale = resolvedLocale;
    _appSettings = _appSettings.copyWith(
      localeCode: language.code,
      clearLocaleCode: language == AppLanguage.system,
    );
    await _settings.saveAppSettings(_appSettings);
    notifyListeners();

    // 화면은 다시 그려지지만 **앱 밖으로 나간 문자열은 그대로 남는다.**
    // 알림은 주 단위로 미리 예약돼 있어, 다시 예약하지 않으면 사용자는
    // 몇 주 동안 옛 언어로 알림을 받는다. 홈 위젯도 마찬가지다.
    if (resolvedLocale != previousLocale) {
      await _syncSideEffects();
    }
  }

  /// [pack]을 지금 쓰는 팩으로 바꾼다. 저장까지 끝나야 true다.
  ///
  /// 고를 수 없는 팩(가지지 않았거나 그림이 없는 팩)은 거절한다. 화면이
  /// 버튼을 잠가 두더라도, 판정은 저장하는 이 자리에서 한 번 더 한다.
  ///
  /// 저장이 실패하면 바꾸기 전으로 되돌린다. 화면만 바뀌고 저장이 안 된
  /// 채로 두면 다음 실행에서 캐릭터가 말없이 옛 팩으로 돌아간다.
  Future<bool> selectCharacterPack(CharacterPack pack) async {
    if (CharacterPackCatalog.byId(pack.id, packs: _characterPacks) == null ||
        !CharacterPackCatalog.isSelectable(pack, _packOwnership)) {
      return false;
    }
    if (pack.id == currentPack.id) return true;

    // 되돌릴 때는 팩 필드만 되돌린다. 저장을 기다리는 사이 언어 같은 다른
    // 설정이 바뀌었을 수 있다. null은 copyWith로 되돌릴 수 없으므로 같은
    // 뜻인 기본 팩 ID로 적는다.
    final previousId =
        _appSettings.characterPackId ?? CharacterPackCatalog.defaultPack.id;
    _appSettings = _appSettings.copyWith(characterPackId: pack.id);
    notifyListeners();
    try {
      await _settings.saveAppSettings(_appSettings);
    } catch (e, st) {
      debugPrint('selectCharacterPack save failed: $e\n$st');
      _appSettings = _appSettings.copyWith(characterPackId: previousId);
      notifyListeners();
      return false;
    }
    return true;
  }

  /// 보상형 광고를 끝까지 보면 [pack]을 하루 동안 열고 바로 적용한다.
  ///
  /// 광고를 보고 나서 «쓰기»를 한 번 더 누르게 하면, 사용자는 30초를 내고도
  /// 아무것도 바뀌지 않은 화면을 먼저 본다.
  Future<PackTrialOutcome> watchAdForPackTrial(CharacterPack pack) async {
    if (!_packOwnership.canStartTrial(pack)) return PackTrialOutcome.failed;

    final outcome = await _showRewardedAd(AdSlot.packTrialReward);
    switch (outcome) {
      case RewardedAdOutcome.earned:
        break;
      case RewardedAdOutcome.dismissed:
        return PackTrialOutcome.adNotCompleted;
      case RewardedAdOutcome.dailyCapReached:
        return PackTrialOutcome.dailyLimitReached;
      case RewardedAdOutcome.unavailable:
        return PackTrialOutcome.adUnavailable;
    }

    final endsAt = _now.add(RewardedTrialOwnership.trialLength);
    // 광고는 이미 봤다. 저장이 실패해도 이번 실행 동안은 열어 둔다 —
    // 30초를 낸 사람에게 «실패»를 돌려주는 것보다, 다시 켰을 때 잠기는 편이 낫다.
    try {
      await _packTrialStore.saveTrialEnd(pack.id, endsAt);
    } catch (e, st) {
      debugPrint('pack trial save failed: $e\n$st');
    }
    _setPackTrialEnds({..._packTrialEnds, pack.id: endsAt});
    notifyListeners();

    return await selectCharacterPack(pack)
        ? PackTrialOutcome.started
        : PackTrialOutcome.failed;
  }

  /// 광고로 연 팩의 끝나는 시각들. 광고를 켤 수 없는 플랫폼은 읽지 않는다.
  ///
  /// 실패해도 로드를 막지 않는다 — 체험이 사라질 뿐 루틴은 그대로 보여야 한다.
  Future<Map<String, DateTime>> _loadPackTrialEnds() async {
    if (!_rewardedPackTrials) return const {};
    try {
      return await _packTrialStore.loadTrialEnds();
    } catch (e, st) {
      debugPrint('pack trial load failed: $e\n$st');
      return const {};
    }
  }

  /// 끝난 체험을 판정 객체에서 걷어 낸다.
  ///
  /// 판정은 시각으로 하므로 걷어 내지 않아도 결과는 같다. 다만 판정 객체가
  /// 그대로면 스코프가 팩 화면에 알리지 않아, 쓰지 않던 팩의 체험이 끝나도
  /// 상세 화면이 «체험 중»으로 남는다.
  void _dropExpiredPackTrials() {
    if (!_packOwnership.hasExpiredEntries()) return;
    final now = _now;
    _setPackTrialEnds({
      for (final entry in _packTrialEnds.entries)
        if (now.isBefore(entry.value)) entry.key: entry.value,
    });
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
    try {
      await _data.upsertLog(outcome.log);
    } catch (e, st) {
      // 성공 스낵바를 띄워도 되는지는 저장소 쓰기 성공 여부로만 정한다.
      // 화면이 현재 언어로 실패 문구를 고를 수 있도록 예외는 다시 올린다.
      debugPrint('routine action write failed: $e\n$st');
      rethrow;
    }

    // 쓰기가 끝난 뒤 다시 읽다가 실패해도 이미 저장된 기록을 실패로
    // 오해하면 안 된다. 저장한 결과로 메모리 상태를 바로 갱신한다.
    _upsertTodayLogInMemory(outcome.log);
    notifyListeners();
    await _pushHomeWidget();
    await _syncSnoozeAlarm(c, outcome.log);
    return RoutineActionUndo(
      routineId: c.id,
      dateYmd: ymd,
      previousLog: log,
    );
  }

  /// 바로 직전에 기록한 완료·미루기·스킵 동작을 되돌린다.
  Future<void> undoAction(RoutineActionUndo undo) async {
    try {
      if (undo.previousLog == null) {
        await _data.deleteLogForRoutineOnDate(undo.routineId, undo.dateYmd);
      } else {
        await _data.upsertLog(undo.previousLog!);
      }
    } catch (e, st) {
      debugPrint('routine action undo write failed: $e\n$st');
      rethrow;
    }

    if (undo.previousLog == null) {
      _logsToday.removeWhere(
        (item) =>
            item.routineId == undo.routineId && item.dateYmd == undo.dateYmd,
      );
    } else {
      _upsertTodayLogInMemory(undo.previousLog!);
    }
    notifyListeners();
    await _pushHomeWidget();
    final routine = _routineById(undo.routineId);
    if (routine != null) {
      await _syncSnoozeAlarm(routine, undo.previousLog);
    }
  }

  Routine? _routineById(String id) {
    for (final routine in _routines) {
      if (routine.id == id) return routine;
    }
    return null;
  }

  /// 미뤄둔 재알림을 **지금 기록 상태에 맞춘다.**
  ///
  /// 기록이 바뀔 때마다 부른다. 미룬 상태면 그 시각에 걸고, 완료·건너뛰기로
  /// 끝났거나 되돌려서 미룬 적이 없게 되면 거둔다. 이미 지난 시각이면 걸지
  /// 않는다 — 걸어 봐야 즉시 울리거나 조용히 버려진다.
  ///
  /// 부수 효과다. 여기서 터져도 기록은 이미 저장됐으므로 삼킨다.
  Future<void> _syncSnoozeAlarm(Routine routine, RoutineLog? log) async {
    if (kIsWeb) return;

    final until = log != null && log.status == RoutineLogStatus.snoozed
        ? log.snoozedUntilMs
        : null;
    try {
      if (until == null) {
        await _notifications.cancelSnooze(routine.id);
        return;
      }
      final when = DateTime.fromMillisecondsSinceEpoch(until);
      if (!when.isAfter(_now)) {
        await _notifications.cancelSnooze(routine.id);
        return;
      }
      await _notifications.scheduleSnooze(routine, when, strings);
    } catch (e, st) {
      debugPrint('snooze alarm sync failed: $e\n$st');
    }
  }

  void _upsertTodayLogInMemory(RoutineLog log) {
    final index = _logsToday.indexWhere(
      (item) => item.routineId == log.routineId && item.dateYmd == log.dateYmd,
    );
    if (index == -1) {
      _logsToday.add(log);
    } else {
      _logsToday[index] = log;
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
      _dropExpiredPackTrials();

      notifyListeners();
      if (!kIsWeb) {
        await HomeWidgetSyncService.instance
            .push(_snapshotForBackground, strings);
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
