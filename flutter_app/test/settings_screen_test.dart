import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_doubles.dart';

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

  Future<RoutineAppController> pumpSettings(WidgetTester tester) async {
    final controller = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: MemoryRoutineRepository([
          dailyRoutine(id: 'wake', title: '기상', startHour: 7, endHour: 8),
        ]),
        logRepository: MemoryLogRepository(),
      ),
      notificationService: RoutineNotificationService(
        gateway: NoopNotificationGateway(),
        preferencesLoader: () async =>
            NotificationPreferences.firstLaunchDefaults,
      ),
      nowProvider: () => DateTime(2026, 8, 4, 10, 0),
      clockAutoRefreshEnabled: false,
    );
    await controller.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('탭 목적지이므로 뒤로가기 버튼을 두지 않는다', (tester) async {
    final controller = await pumpSettings(tester);
    addTearDown(controller.dispose);

    expect(find.text('설정'), findsWidgets);
    expect(find.byTooltip('뒤로'), findsNothing);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
  });

  testWidgets('채울 수 없는 스트릭·상태 지표를 하드코딩해 보여주지 않는다', (tester) async {
    final controller = await pumpSettings(tester);
    addTearDown(controller.dispose);

    // 이전 프로필 카드는 로그와 무관하게 항상 '3일'을 보여줬다.
    expect(find.textContaining('연속 루틴'), findsNothing);
    expect(find.textContaining('이어가는 중'), findsNothing);
    expect(find.text('기분 좋은 하루'), findsNothing);
    expect(find.text('루틴 진행 중'), findsNothing);
  });

  testWidgets('준비 중 항목은 배지로 알리고 이동 화살표를 두지 않는다', (tester) async {
    final controller = await pumpSettings(tester);
    addTearDown(controller.dispose);

    expect(find.text('준비 중'), findsWidgets);
    // 갈 곳이 없는 행에 화살표/줄표를 남기지 않는다.
    expect(find.byIcon(Icons.remove_rounded), findsNothing);
  });

  testWidgets('알림 소리는 푸시 알림이 꺼져 있으면 함께 비활성된다', (tester) async {
    final controller = await pumpSettings(tester);
    addTearDown(controller.dispose);

    expect(find.text('푸시 알림'), findsOneWidget);
    expect(find.text('알림 소리'), findsOneWidget);
    // 비활성 이유를 설명 문구로 함께 보여준다.
    expect(find.text('푸시 알림이 켜져 있을 때만 쓸 수 있어요'), findsOneWidget);
  });
}
