import 'package:home_widget/home_widget.dart';

import '../application/home/home_snapshot.dart';
import 'system_home_widget_payload.dart';

/// [HomeSnapshot] → `home_widget` 저장 및 네이티브 위젯 갱신.
///
/// iOS: [init]에서 App Group 필요. Android: App Group 무시.
class HomeWidgetSyncService {
  HomeWidgetSyncService._();
  static final HomeWidgetSyncService instance = HomeWidgetSyncService._();

  static const appGroupId = 'group.com.example.routineTimer';

  /// Android: [RoutineMediumWidgetProvider] 클래스 단순명, 전체 FQCN도 함께 전달.
  static const androidWidgetName = 'RoutineMediumWidgetProvider';
  static const androidWidgetQualifiedName =
      'com.example.routine_timer.RoutineMediumWidgetProvider';

  static const iosWidgetKind = 'RoutineMediumWidget';

  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    await HomeWidget.setAppGroupId(appGroupId);
    _inited = true;
  }

  Future<void> push(HomeSnapshot snapshot) async {
    await init();
    final payload = SystemHomeWidgetPayload.fromHomeSnapshot(snapshot);
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
