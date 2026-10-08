import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../application/services/routine_notification_service.dart';
import '../data/local/local_routine_log_repository.dart';
import '../data/local/local_routine_repository.dart';
import '../data/local/local_settings_repository.dart';
import '../data/store/character_pack_catalog.dart';
import '../domain/services/routine_occurrences.dart';
import '../domain/settings/app_language.dart';
import '../l10n/app_localizations.dart';
import 'home_widget_sync_service.dart';
import 'widget_completion_service.dart';
import 'widget_routine_target.dart';

Future<void> _pendingWidgetAction = Future.value();

@pragma('vm:entry-point')
Future<void> routineWidgetBackgroundAction(Uri? uri) {
  WidgetsFlutterBinding.ensureInitialized();
  // The background worker can deliver several rapid taps to the same engine.
  return _pendingWidgetAction = _pendingWidgetAction
      .then((_) => _completeAndRefresh(uri))
      .catchError((Object error, StackTrace stack) {
    debugPrint('widget completion failed: $error\n$stack');
  });
}

Future<void> _completeAndRefresh(Uri? uri) async {
  final target = WidgetRoutineTarget.parse(uri);
  if (target == null) return;
  final routines = LocalRoutineRepository.instance;
  final logs = LocalRoutineLogRepository.instance;
  final now = DateTime.now();
  final changed = await WidgetCompletionService(routines: routines, logs: logs)
      .complete(uri, now);
  if (changed) {
    try {
      await RoutineNotificationService().cancelSnooze(target.routineId);
    } catch (e) {
      debugPrint('widget snooze cancellation failed: $e');
    }
  }
  // Refresh even for stale taps so a deleted/finished occurrence disappears.
  await initializeDateFormatting();
  final settingsRepo = LocalSettingsRepository.instance;
  await settingsRepo.reload();
  final settings = await settingsRepo.loadAppSettings();
  final language = AppLanguage.fromCode(settings.localeCode ??
      WidgetsBinding.instance.platformDispatcher.locale.languageCode);
  final l10n =
      lookupAppLocalizations(language.locale ?? AppLanguage.fallback.locale!);
  // Keep the effective pack selected by the foreground app (including entitlements).
  final pack = await HomeWidget.getWidgetData<String>('routine_widget_pack');
  await HomeWidgetSyncService.instance.push(
    now: now,
    routines: await routines.loadRoutines(),
    logsToday: [
      ...await logs.loadLogsForDate(now),
      ...await logs.loadLogsForDate(RoutineOccurrences.day(now, 1)),
    ],
    l10n: l10n,
    characterPackId: pack ?? CharacterPackCatalog.defaultPack.id,
  );
}
