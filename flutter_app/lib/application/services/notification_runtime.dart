import '../../domain/services/routine_occurrences.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:routine_notification_platform/routine_notification_platform.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../data/local/local_routine_log_repository.dart';
import '../../data/local/local_routine_repository.dart';
import '../../data/local/local_settings_repository.dart';
import '../../data/store/character_pack_catalog.dart';
import '../../domain/models/routine_notification_target.dart';
import '../../domain/settings/app_language.dart';
import '../../l10n/app_localizations.dart';
import '../../widget_home/home_widget_sync_service.dart';
import 'ad_policy_service.dart';
import 'notification_action_service.dart';

const notificationAcknowledgeAction = 'routine_acknowledge';
const notificationSnoozeAction = 'routine_snooze_15';

@pragma('vm:entry-point')
void routineNotificationBackgroundResponse(NotificationResponse response) {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(NotificationRuntime.instance.handle(response));
}

class NotificationOpenRequest {
  const NotificationOpenRequest(this.target, this.dateYmd);
  final RoutineNotificationTarget target;
  final String? dateYmd;
}

/// One initialization owner prevents permission requests from replacing callbacks.
class NotificationRuntime {
  NotificationRuntime._();
  static final instance = NotificationRuntime._();
  final plugin = FlutterLocalNotificationsPlugin();
  final openRequest = ValueNotifier<NotificationOpenRequest?>(null);
  final recordsChanged = ValueNotifier<int>(0);
  Future<void>? _initializing;
  Future<void> _responses = Future.value();

  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    if (kIsWeb) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        RoutineNotificationPlatform.channel.setMethodCallHandler((call) async {
          if (call.method == 'logsChanged') recordsChanged.value++;
        });
      }
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_notification'),
          iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false),
          macOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false),
        ),
        onDidReceiveNotificationResponse: (response) =>
            unawaited(handle(response)),
        onDidReceiveBackgroundNotificationResponse:
            routineNotificationBackgroundResponse,
      );
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }

  Future<void> readLaunchNotification() async {
    await initialize();
    final details = await plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true &&
        details?.notificationResponse != null) {
      await handle(details!.notificationResponse!);
    }
  }

  Future<void> handle(NotificationResponse response) {
    _responses = _responses
        .then((_) => _handle(response))
        .catchError((Object e, StackTrace st) {
      debugPrint('notification action failed: $e\n$st');
    });
    return _responses;
  }

  Future<void> _handle(NotificationResponse response) async {
    final id = response.id;
    final target = RoutineNotificationTarget.parse(response.payload);
    if (id == null) return;
    final android = defaultTargetPlatform == TargetPlatform.android;
    final postedAt =
        android ? await RoutineNotificationPlatform.postedAt(id) : null;
    final action = response.actionId;
    if (action == notificationAcknowledgeAction) {
      // 알람 소리부터 끈다. 기록 저장은 그 뒤에 해도 늦지 않다.
      await RoutineNotificationPlatform.dismiss(id, postedAt: postedAt);
      if (target == null || postedAt == null) return;
      final now = DateTime.now();
      final completed = await NotificationActionService()
          .complete(target: target, postedAt: postedAt, now: now);
      if (completed) await _pushHomeWidget(now, await _strings());
      return;
    }
    if (action == notificationSnoozeAction) {
      if (target == null || postedAt == null) return;
      final l10n = await _strings();
      final now = DateTime.now();
      final applied = await NotificationActionService()
          .snooze(target: target, postedAt: postedAt, now: now, l10n: l10n);
      // Invalid/stale actions are dismissed, without altering any other routine.
      await RoutineNotificationPlatform.dismiss(id, postedAt: postedAt);
      if (applied) await _pushHomeWidget(now, l10n);
      return;
    }
    if (action != null && action.isNotEmpty) return;
    if (android) {
      await RoutineNotificationPlatform.dismiss(id, postedAt: postedAt);
    }
    if (target == null) return; // Preview notifications have no routine target.
    AdPolicyService.instance.markStartedFromNotification();
    openRequest.value = NotificationOpenRequest(target,
        postedAt == null ? target.dateYmd : target.occurrenceDate(postedAt));
  }

  /// 홈 위젯은 기록을 직접 읽지 않고 여기서 보낸 화면 데이터만 그린다.
  /// 알림에서 기록을 바꿨으면 앱이 꺼져 있어도 바로 다시 보낸다.
  Future<void> _pushHomeWidget(DateTime now, AppLocalizations l10n) async {
    await initializeDateFormatting();
    final settings = await LocalSettingsRepository.instance.loadAppSettings();
    await HomeWidgetSyncService.instance.push(
      now: now,
      routines: await LocalRoutineRepository.instance.loadRoutines(),
      logsToday: [
        ...await LocalRoutineLogRepository.instance.loadLogsForDate(now),
        ...await LocalRoutineLogRepository.instance
            .loadLogsForDate(RoutineOccurrences.day(now, 1)),
      ],
      l10n: l10n,
      characterPackId:
          settings.characterPackId ?? CharacterPackCatalog.defaultPack.id,
    );
  }

  Future<AppLocalizations> _strings() async {
    await LocalSettingsRepository.instance.reload();
    final settings = await LocalSettingsRepository.instance.loadAppSettings();
    final code = settings.localeCode ??
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final language = AppLanguage.fromCode(code);
    return lookupAppLocalizations(
        language.locale ?? AppLanguage.fallback.locale!);
  }
}
