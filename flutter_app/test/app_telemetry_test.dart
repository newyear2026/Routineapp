import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/app_telemetry.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';

import 'support/routine_test_harness.dart';
import 'support/test_doubles.dart';

void main() {
  setUpRoutineTestEnvironment();

  test('screen events exclude queries, identifiers and unnamed dialogs',
      () async {
    final events = <Map<String, Object>>[];
    final telemetry = AppTelemetry(sendEvent: (name, parameters) async {
      events.add({'event': name, ...parameters});
    });
    await telemetry.screenViewed('/home');
    await telemetry.screenViewed('/character-packs/:id');
    await telemetry.screenViewed('/routine-add?id=private-routine');
    await telemetry.screenViewed('/notification-routine?payload=private-data');
    await telemetry.screenViewed('/character-packs/private-id');
    await telemetry.screenViewed(null);
    expect(events, [
      {'event': 'screen_view', 'screen_name': 'home', 'screen_class': 'home'},
      {
        'event': 'screen_view',
        'screen_name': 'character_pack_detail',
        'screen_class': 'character_pack_detail',
      },
    ]);
  });

  test('storage exception content is removed from crash reports', () async {
    String? reportedType;
    StackTrace? reportedStack;
    final stack = StackTrace.current;
    final telemetry = AppTelemetry(
      sendError: (type, trace, reason, fatal) async {
        reportedType = type;
        reportedStack = trace;
      },
    );
    await telemetry.reportError(
      const FormatException('private title', '{"title":"private title"}'),
      stack,
      reason: 'routine_load',
    );
    expect(reportedType, 'FormatException');
    expect(reportedStack, same(stack));
  });

  test('SDK failures do not escape into application actions', () async {
    final telemetry = AppTelemetry(
      sendEvent: (_, __) async => throw StateError('offline'),
      sendError: (_, __, ___, ____) async => throw StateError('offline'),
    );
    await telemetry.routineSaved(created: true);
    await telemetry.reportError(StateError('write'), StackTrace.current,
        reason: 'routine_save');
  });

  test('controller reports persisted actions once without routine content',
      () async {
    final events = <Map<String, Object>>[];
    final telemetry = AppTelemetry(sendEvent: (name, parameters) async {
      events.add({'event': name, ...parameters});
    });
    final controller = _controller(MemoryRoutineRepository(), telemetry);
    addTearDown(controller.dispose);
    await controller.load();
    expect((await controller.saveRoutine(_routine)).ok, isTrue);
    expect(
        (await controller.saveRoutine(_routine.copyWith(title: 'private edit')))
            .ok,
        isTrue);
    final undo = await controller.completeCurrent();
    expect(undo, isNotNull);
    expect(await controller.completeCurrent(), isNull);
    await controller.undoAction(undo!);
    expect((await controller.deleteRoutine(_routine.id)).ok, isTrue);
    expect(events, [
      {'event': 'routine_created'},
      {'event': 'routine_updated'},
      {'event': 'routine_completed', 'action_source': 'app'},
      {'event': 'routine_action_undone'},
      {'event': 'routine_deleted'},
    ]);
  });

  test('failed saves do not count as created routines', () async {
    final events = <String>[];
    final errors = <String>[];
    final controller = _controller(
      _FailingRepository(),
      AppTelemetry(
        sendEvent: (name, _) async => events.add(name),
        sendError: (type, _, reason, __) async => errors.add('$reason:$type'),
      ),
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect((await controller.saveRoutine(_routine)).ok, isFalse);
    expect(events, isEmpty);
    expect(errors, ['routine_save:StateError']);
  });
}

const _routine = Routine(
  id: 'private-routine-id',
  title: 'Private medical routine',
  startMinutesFromMidnight: 9 * 60,
  endMinutesFromMidnight: 10 * 60,
  repeatWeekdays: {1},
  colorValue: 0xFF000000,
  iconEmoji: '🌱',
);

RoutineAppController _controller(
        MemoryRoutineRepository repository, AppTelemetry telemetry) =>
    RoutineAppController(
      dataService: RoutineDataService(
          routineRepository: repository, logRepository: MemoryLogRepository()),
      notificationService: RoutineNotificationService(
        gateway: NoopNotificationGateway(),
        exactAlarmsAllowed: () async => false,
        preferencesLoader: () async =>
            NotificationPreferences.firstLaunchDefaults,
      ),
      completionHaptic: () async {},
      nowProvider: () => DateTime(2026, 10, 5, 9, 30),
      clockAutoRefreshEnabled: false,
      telemetry: telemetry,
    );

class _FailingRepository extends MemoryRoutineRepository {
  @override
  Future<void> upsertRoutine(Routine routine) async =>
      throw StateError('private data must not be reported');
}
