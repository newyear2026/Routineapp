// flutter test tool/render_notification_settings.dart --dart-define=PREVIEW_FONT=/System/Library/Fonts/AppleSDGothicNeo.ttc
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/application/settings/settings_controller.dart';
import 'package:routine_timer/data/local/local_settings_repository.dart';
import 'package:routine_timer/screens/notification_settings_screen.dart';
import 'package:routine_timer/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test/support/localization.dart';
import '../test/support/test_doubles.dart';

void main() {
  testWidgets('Render actual notification settings screen', (tester) async {
    const font = String.fromEnvironment('PREVIEW_FONT');
    await (FontLoader('PreviewKorean')
          ..addFont(
              Future.value(ByteData.sublistView(File(font).readAsBytesSync()))))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    // This tool is executed by flutter test with isolated preferences.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'prefs.notifications.enabled': true,
      'prefs.notifications.permission_status': 'granted',
      'prefs.notifications.sound_enabled': false,
    });
    final repository = LocalSettingsRepository.instance;
    final controller = SettingsController(
        repository: repository,
        logRepository: MemoryLogRepository(),
        notificationService: RoutineNotificationService(
            gateway: NoopNotificationGateway(),
            preferencesLoader: repository.loadNotificationPreferences));
    addTearDown(controller.dispose);
    await controller.load();
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(localizedApp(
        theme: buildRoutineTheme(fontFamily: 'PreviewKorean'),
        home: RepaintBoundary(
            key: key,
            child: NotificationSettingsScreen(
                controller: controller, routines: const []))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final rendered = await boundary.toImage(pixelRatio: 2);
      final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
      rendered.dispose();
      return bytes!.buffer.asUint8List();
    });
    final file = File('design/notification-settings/implemented.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!);
  });
}
