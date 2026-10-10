import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/application/settings/settings_controller.dart';
import 'package:routine_timer/data/local/local_settings_repository.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/screens/notification_settings_screen.dart';
import 'package:routine_timer/widgets/ds/app_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/localization.dart';
import 'support/test_doubles.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'prefs.notifications.enabled': true,
      'prefs.notifications.permission_status': 'granted',
      'prefs.notifications.sound_enabled': false,
    });
  });

  Future<SettingsController> pump(WidgetTester tester,
      {Locale locale = const Locale('ko'),
      double scale = 1,
      Size size = const Size(390, 844)}) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = LocalSettingsRepository.instance;
    final controller = SettingsController(
        repository: repository,
        requestPermission: () async => true,
        logRepository: MemoryLogRepository(),
        notificationService: RoutineNotificationService(
            gateway: NoopNotificationGateway(),
            preferencesLoader: repository.loadNotificationPreferences,
            exactAlarmsAllowed: () async => false));
    addTearDown(controller.dispose);
    await controller.load();
    await tester.pumpWidget(localizedApp(
        locale: locale,
        home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: NotificationSettingsScreen(
                controller: controller, routines: const []))));
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets(
      'mode rows and completion toggle persist; preview uses actual service',
      (tester) async {
    final controller = await pump(tester);
    expect(find.text('소리 + 진동'), findsOneWidget);
    await tester.tap(find.text('화면 알림만'));
    await tester.pumpAndSettle();
    expect(controller.notificationMode, RoutineNotificationMode.visualOnly);
    expect(
        (await LocalSettingsRepository.instance.loadNotificationPreferences())
            .vibrationEnabled,
        isFalse);
    final toggle = find.byKey(const Key('completion-haptic-toggle'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(controller.completionHapticEnabled, isFalse);
    await tester.ensureVisible(find.byType(AppButton));
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('체험 알림을 보냈어요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS does not offer unsupported vibration-only alerts',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await pump(tester);
    expect(find.text('진동만'), findsNothing);
    expect(find.textContaining('iPhone의 알림 진동'), findsOneWidget);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  for (final locale in ['ko', 'en', 'es', 'ja', 'pt']) {
    testWidgets('$locale remains usable at 320px and large text',
        (tester) async {
      await pump(tester,
          locale: Locale(locale), scale: 1.5, size: const Size(320, 568));
      await tester.scrollUntilVisible(find.byType(AppButton), 180,
          scrollable: find.byType(Scrollable).first);
      expect(tester.takeException(), isNull);
      expect(find.byType(AppButton), findsOneWidget);
    });
  }
}
