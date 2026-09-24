import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/screens/home_screen.dart';
import 'package:routine_timer/screens/routines_screen.dart';
import 'package:routine_timer/screens/settings_screen.dart';
import 'package:routine_timer/screens/today_progress_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_doubles.dart';
import 'support/localization.dart';

/// 하단 탭 목적지 네 개는 같은 상단 여백을 쓴다.
///
/// 홈만 다르면 탭을 옮길 때 제목이 그 자리에서 위아래로 튄다. 픽셀 전환에서
/// 홈만 48에서 24로 내려가 이 규칙이 깨졌고, 규칙은 코드 주석에만 있어서
/// 아무것도 막지 못했다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const homeWidgetChannel = MethodChannel('home_widget');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, (call) async => true);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, null);
  });

  /// 화면에서 가장 바깥 스크롤 영역의 여백. 트리 순서상 첫 번째가 바깥이다.
  EdgeInsets outerScrollPadding(WidgetTester tester) {
    final widget = tester
        .widgetList(find.byWidgetPredicate((w) =>
            (w is SingleChildScrollView && w.padding != null) ||
            (w is ListView && w.padding != null)))
        .first;
    final padding = widget is SingleChildScrollView
        ? widget.padding!
        : (widget as ListView).padding!;
    return padding.resolve(TextDirection.ltr);
  }

  Future<double> topPaddingOf(WidgetTester tester, Widget screen) async {
    final controller = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: MemoryRoutineRepository([
          dailyRoutine(id: 'wake', title: '기상', startHour: 7, endHour: 8),
          dailyRoutine(
              id: 'focus',
              title: '집중',
              startHour: 9,
              endHour: 10,
              updatedAtMs: 2),
        ]),
        logRepository: MemoryLogRepository(),
      ),
      notificationService: RoutineNotificationService(
        exactAlarmsAllowed: () async => false,
        gateway: NoopNotificationGateway(),
        preferencesLoader: () async =>
            NotificationPreferences.firstLaunchDefaults,
      ),
      nowProvider: () => DateTime(2026, 8, 4, 9, 30),
      clockAutoRefreshEnabled: false,
    );
    await controller.load();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: localizedApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
    return outerScrollPadding(tester).top;
  }

  testWidgets('탭 목적지 네 화면의 상단 여백이 같다', (tester) async {
    final tops = <String, double>{};
    for (final entry in <String, Widget>{
      '홈': const HomeScreen(),
      '진행': const TodayProgressScreen(),
      '루틴': const RoutinesScreen(),
      '설정': const SettingsScreen(),
    }.entries) {
      tops[entry.key] = await topPaddingOf(tester, entry.value);
    }

    expect(
      tops.values.toSet(),
      hasLength(1),
      reason: '탭마다 상단 여백이 다르면 탭을 옮길 때 제목이 튄다: $tops',
    );
  });
}
