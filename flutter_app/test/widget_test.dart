import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/home/home_snapshot_builder.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/widget_medium/home_medium_widget.dart';
import 'package:routine_timer/widget_medium/home_medium_widget_selector.dart';
import 'package:routine_timer/widget_medium/home_medium_widget_view_model.dart';
import 'package:routine_timer/widget_medium/mini_circular_timetable.dart';
import 'support/localization.dart';

void main() {
  test('home segments and medium ring keep routine end times', () {
    final routines = [
      Routine(
        id: 'morning',
        title: '아침 준비',
        startMinutesFromMidnight: 8 * 60,
        endMinutesFromMidnight: 9 * 60,
        repeatWeekdays: const {3},
        colorValue: const Color(0xFFE91E63).toARGB32(),
        iconEmoji: '🌤️',
      ),
      Routine(
        id: 'study',
        title: '집중 공부',
        startMinutesFromMidnight: 11 * 60,
        endMinutesFromMidnight: 13 * 60,
        repeatWeekdays: const {3},
        colorValue: const Color(0xFF2196F3).toARGB32(),
        iconEmoji: '📚',
      ),
    ];

    final snapshot = HomeSnapshotBuilder.build(
      l10n: testL10n,
      nowLocal: DateTime(2026, 4, 1, 10, 30),
      allRoutines: routines,
      logsToday: const [],
    );
    final medium = HomeMediumWidgetSelector.fromSnapshot(snapshot, testL10n);

    expect(snapshot.segments, hasLength(2));
    expect(snapshot.segments[0].startMinutesFromMidnight, 8 * 60);
    expect(snapshot.segments[0].endMinutesFromMidnight, 9 * 60);
    expect(snapshot.segments[1].startMinutesFromMidnight, 11 * 60);
    expect(snapshot.segments[1].endMinutesFromMidnight, 13 * 60);

    expect(medium.ringSegments, hasLength(2));
    expect(medium.ringSegments[0].sweepMinutes, 60);
    expect(medium.ringSegments[1].sweepMinutes, 120);
  });

  testWidgets('원형 위젯의 다음 일정은 시각 다음에 이름을 표시한다', (tester) async {
    await tester.pumpWidget(localizedApp(
      home: Center(
        child: SizedBox(
          width: 340,
          child: MediaQuery.withNoTextScaling(
            child: HomeMediumWidget(
                viewModel: HomeMediumWidgetViewModel.dummy(testL10n)),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final time = tester.getRect(find.text('18:00'));
    final ring = tester.getRect(find.byType(MiniCircularTimetable));
    final next = tester.getRect(find.text(testL10n.catalogDinner));
    expect(next.left, greaterThan(time.right));
    expect(next.right, lessThan(ring.left));
    expect((next.center.dy - time.center.dy).abs(), lessThan(2));
    expect(find.text(testL10n.widgetComplete), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
