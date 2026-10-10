import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/models/routine_log.dart';
import 'package:routine_timer/domain/models/routine_log_status.dart';
import 'package:routine_timer/domain/models/routine_action_source.dart';
import 'package:routine_timer/widget_home/widget_completion_service.dart';
import 'package:routine_timer/widget_home/widget_routine_target.dart';
import 'package:routine_timer/widget_home/system_home_widget_timeline.dart';
import 'support/test_doubles.dart';
import 'support/localization.dart';

void main() {
  final now = DateTime(2026, 10, 7, 21, 18);
  Routine reading({int version = 1}) =>
      dailyRoutine(id: 'reading', title: '독서', startHour: 21, endHour: 22)
          .copyWith(
              startMinutesFromMidnight: 21 * 60,
              endMinutesFromMidnight: 21 * 60 + 30,
              updatedAtMs: version);

  test(
      'widget completes the displayed occurrence and refresh payload removes action',
      () async {
    final routine = reading();
    final routines = MemoryRoutineRepository([routine]);
    final logs = MemoryLogRepository();
    final service = WidgetCompletionService(routines: routines, logs: logs);
    final payload = SystemHomeWidgetTimeline.build(
        now: now,
        l10n: testL10n,
        routines: routines.items,
        logsToday: logs.logs);
    final uri = Uri.parse(payload.timelineStates.first.completeActionUri!);
    expect(await service.complete(uri, now), isTrue);
    expect(logs.logs.single.status, RoutineLogStatus.completed);
    expect(logs.logs.single.dateYmd, '2026-10-07');
    expect(logs.logs.single.actionSource, RoutineActionSource.widget);
    expect(await service.complete(uri, now), isFalse);
    expect(logs.logs, hasLength(1));
    final completed = SystemHomeWidgetTimeline.build(
        now: now,
        l10n: testL10n,
        routines: routines.items,
        logsToday: logs.logs);
    expect(completed.timelineStates.first.completeActionUri, isNull);
    expect(completed.timelineStates.first.timingTargetEpochMs, isNull);
  });

  test(
      'stale, modified, deleted and malformed actions cannot change another slot',
      () async {
    final routine = reading();
    final routines = MemoryRoutineRepository([routine]);
    final logs = MemoryLogRepository();
    final service = WidgetCompletionService(routines: routines, logs: logs);
    final uri = WidgetRoutineTarget.forRoutine(routine, now).uri;
    expect(await service.complete(uri, DateTime(2026, 10, 8, 21, 18)), isFalse);
    expect(await service.complete(uri, DateTime(2026, 10, 7, 21, 30)), isFalse);
    expect(await service.complete(uri, DateTime(2026, 10, 7, 20, 59)), isFalse);
    await routines.upsertRoutine(reading(version: 2));
    expect(await service.complete(uri, now), isFalse);
    routines.items.clear();
    expect(await service.complete(uri, now), isFalse);
    for (final bad in [
      null,
      Uri.parse('loopet-widget://complete'),
      Uri.parse('other://complete?id=reading'),
      uri.replace(
          queryParameters: {...uri.queryParameters, 'date': '2026-02-31'})
    ]) {
      expect(await service.complete(bad, now), isFalse);
    }
    expect(logs.logs, isEmpty);
  });

  test(
      'overlapping routines: action targets its own ID; skipped logs are preserved',
      () async {
    final first = reading();
    final second = first.copyWith(id: 'second', updatedAtMs: 2);
    final routines = MemoryRoutineRepository([first, second]);
    final logs = MemoryLogRepository();
    final service = WidgetCompletionService(routines: routines, logs: logs);
    expect(
        await service.complete(
            WidgetRoutineTarget.forRoutine(first, now).uri, now),
        isTrue);
    expect(logs.logs.single.routineId, 'reading');
    const skipped = RoutineLog(
        id: 'second_2026-10-07',
        routineId: 'second',
        dateYmd: '2026-10-07',
        status: RoutineLogStatus.skipped);
    await logs.upsertLog(skipped);
    expect(
        await service.complete(
            WidgetRoutineTarget.forRoutine(second, now).uri, now),
        isFalse);
    expect(logs.logs.last.status, RoutineLogStatus.skipped);
  });

  test('sleep completion is recorded on its wake date across midnight',
      () async {
    final sleep =
        dailyRoutine(id: 'sleep', title: '취침', startHour: 23, endHour: 7)
            .copyWith(
                type: RoutineType.sleep,
                startMinutesFromMidnight: 23 * 60,
                endMinutesFromMidnight: 7 * 60);
    final bedtime = DateTime(2026, 10, 7, 23, 15);
    final target = WidgetRoutineTarget.forRoutine(sleep, bedtime);
    final logs = MemoryLogRepository();
    final service = WidgetCompletionService(
        routines: MemoryRoutineRepository([sleep]), logs: logs);
    expect(target.dateYmd, '2026-10-08');
    expect(await service.complete(target.uri, DateTime(2026, 10, 8, 7, 5)),
        isTrue);
    expect(logs.logs.single.dateYmd, '2026-10-08');
  });

  test('future boundaries carry their own action and upcoming states have none',
      () {
    final routine = reading();
    final payload = SystemHomeWidgetTimeline.build(
        now: DateTime(2026, 10, 7, 20),
        l10n: testL10n,
        routines: [routine],
        logsToday: []);
    expect(payload.completeActionUri, isNull);
    final active = payload.timelineStates.singleWhere((s) =>
        s.effectiveAtEpochMs ==
        DateTime(2026, 10, 8, 21).millisecondsSinceEpoch);
    expect(
        WidgetRoutineTarget.parse(Uri.parse(active.completeActionUri!))!
            .dateYmd,
        '2026-10-08');
    expect(active.toJson()['completeLabel'], isNotEmpty);
  });
}
