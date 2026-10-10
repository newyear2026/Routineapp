import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:routine_timer/application/home/home_snapshot_builder.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/l10n/app_localizations.dart';
import 'package:routine_timer/widget_home/system_home_widget_timeline.dart';
import 'package:routine_timer/widget_medium/home_medium_widget.dart';
import 'package:routine_timer/widget_medium/home_medium_widget_selector.dart';

import 'support/localization.dart';
import 'support/test_doubles.dart';

void main() {
  setUpAll(initializeDateFormatting);
  final now = DateTime(2026, 10, 8, 21, 18);
  List<Routine> routines(AppLocalizations l10n) => [
        dailyRoutine(
                id: 'reading',
                title: l10n.catalogBreak,
                startHour: 21,
                endHour: 22)
            .copyWith(endMinutesFromMidnight: 1290),
        dailyRoutine(
                id: 'stretch',
                title: l10n.catalogDinner,
                startHour: 21,
                endHour: 22)
            .copyWith(startMinutesFromMidnight: 1290),
        dailyRoutine(
            id: 'sleep', title: l10n.catalogSleep, startHour: 22, endHour: 23),
        dailyRoutine(id: 'later', title: 'Later', startHour: 23, endHour: 24),
      ];

  test(
      'rail serializes current + next two occurrences and advances at boundaries',
      () {
    final payload = SystemHomeWidgetTimeline.build(
        now: now,
        routines: routines(testL10n),
        logsToday: const [],
        l10n: testL10n);
    expect(payload.timelineItems.map((e) => e.id),
        ['reading', 'stretch', 'sleep']);
    expect(
        payload.timelineItems.map((e) => e.time), ['21:00', '21:30', '22:00']);
    expect(payload.timelineItems.first.startEpochMs,
        DateTime(2026, 10, 8, 21).millisecondsSinceEpoch);
    final serialized = payload
        .withCharacterPack('poodle_garden')
        .toJson()['timelineItems'] as List;
    expect(serialized.first['title'], testL10n.catalogBreak);
    final next = payload.timelineStates.singleWhere((s) =>
        s.effectiveAtEpochMs ==
        DateTime(2026, 10, 8, 21, 30).millisecondsSinceEpoch);
    expect(next.timelineItems.map((e) => e.id), ['stretch', 'sleep', 'later']);
    expect(next.toJson()['timelineItems'], hasLength(3));
  });

  test('empty/single schedules do not invent extra milestones', () {
    for (final count in [0, 1, 2]) {
      final payload = SystemHomeWidgetTimeline.build(
          now: now,
          routines: routines(testL10n).take(count).toList(),
          logsToday: const [],
          l10n: testL10n);
      expect(payload.timelineItems, hasLength(count));
    }
  });

  test('overnight sleep milestone uses the preceding start date', () {
    final sleep =
        dailyRoutine(id: 'sleep', title: 'Sleep', startHour: 22, endHour: 7)
            .copyWith(type: RoutineType.sleep);
    final morning = dailyRoutine(
        id: 'breakfast', title: 'Breakfast', startHour: 8, endHour: 9);
    final payload = SystemHomeWidgetTimeline.build(
        now: DateTime(2026, 10, 9, 1),
        routines: [sleep, morning],
        logsToday: const [],
        l10n: testL10n);
    expect(payload.timelineItems.first.id, 'sleep');
    expect(payload.timelineItems.first.startEpochMs,
        DateTime(2026, 10, 8, 22).millisecondsSinceEpoch);
    expect(payload.timelineItems[1].startEpochMs,
        DateTime(2026, 10, 9, 8).millisecondsSinceEpoch);
  });

  for (final language in ['ko', 'en', 'es', 'ja', 'pt']) {
    for (final width in [250.0, 360.0]) {
      testWidgets(
          'timeline $language at $width keeps its completion action usable',
          (tester) async {
        final locale = Locale(language);
        final l10n = lookupAppLocalizations(locale);
        final vm = HomeMediumWidgetSelector.fromSnapshot(
            HomeSnapshotBuilder.build(
                nowLocal: now,
                allRoutines: routines(l10n),
                logsToday: const [],
                l10n: l10n),
            l10n);
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = Size(width, 180);
        addTearDown(tester.view.reset);
        var completions = 0;
        await tester.pumpWidget(localizedApp(
            locale: locale,
            home: Material(
                child: HomeMediumWidget(
                    viewModel: vm,
                    style: HomeWidgetStyle.timeline,
                    onComplete: () => completions++))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('21:00'), findsOneWidget);
        expect(find.text('21:30'), findsOneWidget);
        expect(find.text('22:00'), findsOneWidget);
        expect(find.text('23:00'), findsNothing);
        await tester.tap(find.text(l10n.widgetComplete));
        expect(completions, 1);
      });
    }
  }
}
