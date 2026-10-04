import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/domain/models/routine_log_status.dart';
import 'package:routine_timer/domain/models/routine_notification_target.dart';
import 'package:routine_timer/screens/notification_routine_screen.dart';

import 'support/localization.dart';
import 'support/routine_test_harness.dart';
import 'support/test_doubles.dart';

void main() {
  setUpRoutineTestEnvironment();
  final reading =
      dailyRoutine(id: 'reading', title: '독서', startHour: 9, endHour: 10);
  final other = dailyRoutine(
      id: 'other', title: '운동', startHour: 9, endHour: 10, updatedAtMs: 2);
  final target = RoutineNotificationTarget.forRoutine(reading, weekday: 7);
  late MemoryLogRepository logs;
  late RoutineAppController app;

  setUp(() async {
    logs = MemoryLogRepository();
    app = createTestRoutineController(
      now: DateTime(2026, 10, 4, 9, 5),
      routines: [reading, other],
      logRepository: logs,
    );
    await app.load();
  });

  tearDown(() => app.dispose());

  Future<void> show(WidgetTester tester,
      {RoutineNotificationTarget? selected, String date = '2026-10-04'}) async {
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: app,
        child: localizedApp(
            home: NotificationRoutineScreen(
                target: selected ?? target, dateYmd: date))));
    await tester.pumpAndSettle();
  }

  testWidgets('overlapping alert opens and completes its own routine',
      (tester) async {
    await show(tester);
    expect(app.currentRoutine!.id, other.id);
    expect(find.text('독서'), findsOneWidget);
    expect(find.text('운동'), findsNothing);
    await tester.tap(find.text(testL10n.actionCompleteNamed('독서')));
    await tester.pumpAndSettle();
    expect(logs.logs.single.routineId, reading.id);
    expect(logs.logs.single.status, RoutineLogStatus.completed);
    expect(find.text(testL10n.slotAlreadyCompleted), findsOneWidget);
    expect(find.text(testL10n.actionCompleteNamed('독서')), findsNothing);
  });

  testWidgets('old occurrence remains readable without a completion button',
      (tester) async {
    await show(tester, date: '2026-09-27');
    expect(find.text('독서'), findsOneWidget);
    expect(find.text(testL10n.notificationOccurrenceExpired), findsOneWidget);
    expect(find.text(testL10n.actionCompleteNamed('독서')), findsNothing);
    expect(logs.logs, isEmpty);
  });

  testWidgets('deleted routine shows the missing message', (tester) async {
    await show(tester,
        selected: const RoutineNotificationTarget(routineId: 'deleted'));
    expect(find.text(testL10n.routineMissingTitle), findsOneWidget);
    expect(find.text(testL10n.routineMissingBody), findsOneWidget);
    expect(logs.logs, isEmpty);
  });
}
