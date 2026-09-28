import 'package:home_widget/home_widget.dart';

import '../domain/models/routine.dart';
import '../domain/models/routine_log.dart';
import '../l10n/app_localizations.dart';
import 'system_home_widget_payload.dart';
import 'system_home_widget_timeline.dart';

/// 현재 루틴·로그에서 미래 상태를 계산해 `home_widget`에 저장하고 갱신한다.
///
/// iOS: [init]에서 App Group 필요. Android: App Group 무시.
class HomeWidgetSyncService {
  HomeWidgetSyncService._();
  static final HomeWidgetSyncService instance = HomeWidgetSyncService._();

  static const appGroupId = 'group.com.dayround.app';

  /// Android: [RoutineMediumWidgetProvider] 클래스 단순명, 전체 FQCN도 함께 전달.
  static const androidWidgetName = 'RoutineMediumWidgetProvider';
  static const androidWidgetQualifiedName =
      'com.dayround.app.RoutineMediumWidgetProvider';

  static const iosWidgetKind = 'RoutineMediumWidget';

  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    await HomeWidget.setAppGroupId(appGroupId);
    _inited = true;
  }

  Future<void> push({
    required DateTime now,
    required List<Routine> routines,
    required List<RoutineLog> logsToday,
    required AppLocalizations l10n,
    required String characterPackId,
  }) async {
    await init();
    final payload = SystemHomeWidgetTimeline.build(
      now: now,
      l10n: l10n,
      routines: routines,
      logsToday: logsToday,
    ).withCharacterPack(characterPackId);
    await HomeWidget.saveWidgetData<String>(
      SystemHomeWidgetPayload.storageKey,
      payload.encode(),
    );
    await HomeWidget.updateWidget(
      androidName: androidWidgetName,
      qualifiedAndroidName: androidWidgetQualifiedName,
      iOSName: iosWidgetKind,
    );
  }
}
