import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/widget_home/home_widget_sync_service.dart';

import 'support/localization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('home_widget');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('Android 루틴 갱신은 세 가지 위젯을 모두 갱신한다', () async {
    await HomeWidgetSyncService.instance.push(
      now: DateTime(2026, 4, 1, 10),
      routines: const [],
      logsToday: const [],
      l10n: testL10n,
      characterPackId: 'poodle_garden',
    );

    final updates = calls.where((call) => call.method == 'updateWidget');
    expect(
      updates.map((call) => (call.arguments as Map)['qualifiedAndroidName']),
      [
        'com.dayround.app.RoutineMediumWidgetProvider',
        'com.dayround.app.RoutineTimelineWidgetProvider',
        'com.dayround.app.RoutineCardsWidgetProvider',
      ],
    );
    expect(calls.where((call) => call.method == 'saveWidgetData'), hasLength(1));
  });
}
