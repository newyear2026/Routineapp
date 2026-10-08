import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:routine_timer/data/local/local_routine_log_repository.dart';
import 'package:routine_timer/domain/models/routine_log_status.dart';
import 'package:routine_timer/widget_home/widget_interactivity.dart';
import 'package:routine_timer/widget_home/widget_routine_target.dart';
import 'support/test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('background callback persists once and updates all native widgets',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final now = DateTime.now();
    final routine = dailyRoutine(
        id: 'background-test', title: 'Reading', startHour: 0, endHour: 24);
    SharedPreferences.setMockInitialValues({
      'domain.routines.v1': jsonEncode([routine.toJson()]),
      'domain.routine_logs.v1': '[]',
    });
    final calls = <MethodCall>[];
    const channel = MethodChannel('home_widget');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'getWidgetData' ? 'cat_starlight' : true;
    });
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    final uri = WidgetRoutineTarget.forRoutine(routine, now).uri;
    await Future.wait([
      routineWidgetBackgroundAction(uri),
      routineWidgetBackgroundAction(uri),
    ]);
    final logs = await LocalRoutineLogRepository.instance.loadAllLogs();
    expect(logs, hasLength(1));
    expect(logs.single.status, RoutineLogStatus.completed);
    final payload = calls
        .where((call) => call.method == 'saveWidgetData')
        .map((call) => call.arguments as Map)
        .where((args) => args['id'] == 'routine_widget_payload')
        .last;
    final decoded = jsonDecode(payload['data'] as String) as Map;
    expect(decoded['completeActionUri'], isNull);
    final updates = calls
        .where((call) => call.method == 'updateWidget')
        .map((call) => (call.arguments as Map)['qualifiedAndroidName'])
        .toSet();
    expect(updates, {
      'com.dayround.app.RoutineCardsWidgetProvider',
      'com.dayround.app.RoutineMediumWidgetProvider',
      'com.dayround.app.RoutineTimelineWidgetProvider',
    });
  });
}
