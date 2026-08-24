import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/home/home_snapshot_builder.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/services/home_routine_schedule.dart';

import 'support/test_doubles.dart';
import 'support/localization.dart';

void main() {
  final routines = <Routine>[
    dailyRoutine(id: 'wake', title: '기상', startHour: 7, endHour: 8),
    dailyRoutine(id: 'lunch', title: '점심식사', startHour: 12, endHour: 13),
    dailyRoutine(id: 'dinner', title: '저녁식사', startHour: 18, endHour: 19),
    dailyRoutine(id: 'sleep', title: '취침', startHour: 23, endHour: 24),
  ];

  group('HomeRoutineSchedule.routinesAfter', () {
    test('기준 루틴 이후를 시간순으로 모두 돌려준다', () {
      final after = HomeRoutineSchedule.routinesAfter(routines[1], routines);
      expect(after.map((r) => r.id), ['dinner', 'sleep']);
    });

    test('마지막 루틴 뒤는 비어 있다', () {
      expect(HomeRoutineSchedule.routinesAfter(routines.last, routines),
          isEmpty);
    });

    test('첫 항목은 routineAfter와 일치한다', () {
      // 두 API가 어긋나면 화면이 같은 루틴을 두 번 그리게 된다.
      expect(
        HomeRoutineSchedule.routinesAfter(routines.first, routines).first.id,
        HomeRoutineSchedule.routineAfter(routines.first, routines)!.id,
      );
    });
  });

  group('HomeSnapshot.upcomingRoutines', () {
    test('진행 중인 루틴이 없으면 다음 루틴 이후만 담는다', () {
      final snapshot = HomeSnapshotBuilder.build(
        l10n: testL10n,
        nowLocal: DateTime(2026, 8, 4, 16, 24),
        allRoutines: routines,
        logsToday: const [],
      );

      expect(snapshot.currentRoutine, isNull);
      expect(snapshot.displayRoutine?.id, 'dinner');
      // 저녁식사는 포커스 스트립이 맡으므로 목록에 다시 넣지 않는다.
      expect(snapshot.upcomingRoutines.map((r) => r.id), ['sleep']);
      expect(snapshot.nextAfterDisplay?.id, 'sleep');
    });

    test('진행 중이면 그 뒤의 루틴들을 담는다', () {
      final snapshot = HomeSnapshotBuilder.build(
        l10n: testL10n,
        nowLocal: DateTime(2026, 8, 4, 12, 30),
        allRoutines: routines,
        logsToday: const [],
      );

      expect(snapshot.currentRoutine?.id, 'lunch');
      expect(snapshot.upcomingRoutines.map((r) => r.id), ['dinner', 'sleep']);
    });

    test('nextAfterDisplay는 항상 upcomingRoutines의 첫 항목이다', () {
      for (final hour in [0, 7, 12, 16, 18, 23]) {
        final snapshot = HomeSnapshotBuilder.build(
        l10n: testL10n,
          nowLocal: DateTime(2026, 8, 4, hour, 30),
          allRoutines: routines,
          logsToday: const [],
        );
        expect(
          snapshot.nextAfterDisplay?.id,
          snapshot.upcomingRoutines.isEmpty
              ? isNull
              : snapshot.upcomingRoutines.first.id,
          reason: '$hour시 기준 불일치 — 목록 첫 항목이 중복 렌더된다',
        );
      }
    });

    test('오늘 일정이 끝났으면 비어 있다', () {
      final snapshot = HomeSnapshotBuilder.build(
        l10n: testL10n,
        nowLocal: DateTime(2026, 8, 4, 23, 59),
        allRoutines: routines,
        logsToday: const [],
      );
      expect(snapshot.upcomingRoutines, isEmpty);
    });

    test('오늘 루틴이 없으면 비어 있고 빈 하루로 표시된다', () {
      final snapshot = HomeSnapshotBuilder.build(
        l10n: testL10n,
        nowLocal: DateTime(2026, 8, 4, 9, 0),
        allRoutines: const [],
        logsToday: const [],
      );
      expect(snapshot.upcomingRoutines, isEmpty);
      expect(snapshot.isEmptyDay, isTrue);
    });
  });
}
