import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/l10n/app_localizations.dart';
import 'package:routine_timer/widget_home/system_home_widget_timeline.dart';

import 'support/localization.dart';

void main() {
  Routine routine(String id, int start, int end) => Routine(
        id: id,
        title: id,
        startMinutesFromMidnight: start,
        endMinutesFromMidnight: end,
        repeatWeekdays: const {3},
        colorValue: const Color(0xFF6744F4).toARGB32(),
        iconEmoji: '',
      );

  test('앱이 꺼져도 루틴 시작·종료 경계의 상태를 고를 수 있다', () {
    final now = DateTime(2026, 4, 1, 10);
    final payload = SystemHomeWidgetTimeline.build(
      now: now,
      l10n: testL10n,
      routines: [routine('공부', 11 * 60, 12 * 60)],
      logsToday: const [],
    );

    final states = payload.timelineStates;
    final at11 = states.singleWhere((s) =>
        s.effectiveAtEpochMs == DateTime(2026, 4, 1, 11).millisecondsSinceEpoch);
    final at12 = states.singleWhere((s) =>
        s.effectiveAtEpochMs == DateTime(2026, 4, 1, 12).millisecondsSinceEpoch);
    final tomorrow = states.singleWhere((s) =>
        s.effectiveAtEpochMs == DateTime(2026, 4, 2).millisecondsSinceEpoch);

    expect(payload.nextRoutineTitle, testL10n.widgetNone);
    expect(states.first.currentRoutineTitle, '공부');
    expect(states.first.timingMode, 'start');
    expect(at11.currentRoutineTitle, '공부');
    expect(at11.timingMode, 'end');
    expect(at11.timingTargetEpochMs,
        DateTime(2026, 4, 1, 12).millisecondsSinceEpoch);
    expect(at12.currentRoutineTitle, testL10n.widgetNoRoutines);
    expect(at12.nextRoutineTitle, testL10n.widgetNone);
    expect(tomorrow.ringSegments, isEmpty);
    expect(payload.nextLabel, testL10n.commonNext);
    expect(payload.validUntilEpochMs,
        DateTime(2026, 4, 8).millisecondsSinceEpoch);
    expect(payload.withCharacterPack('poodle_garden').toJson()['characterPackId'],
        'poodle_garden');
  });

  test('4×2 링에 표시 루틴의 시간대와 이어지는 루틴 3개를 넘긴다', () {
    final payload = SystemHomeWidgetTimeline.build(
      now: DateTime(2026, 4, 1, 8),
      l10n: testL10n,
      routines: [
        routine('아침', 9 * 60, 10 * 60),
        routine('공부', 11 * 60, 12 * 60),
        routine('점심', 12 * 60, 13 * 60),
        routine('운동', 18 * 60, 19 * 60),
        routine('독서', 21 * 60, 22 * 60),
      ],
      logsToday: const [],
    );

    // 표시 루틴(아침)은 목록에서 빠지고, 뒤따르는 루틴은 3개까지만 간다.
    expect(payload.currentRoutineTimeRange, contains('09:00'));
    expect(payload.upcomingRoutines.map((r) => r.title), ['공부', '점심', '운동']);
    expect(payload.upcomingRoutines.first.time, '11:00');
    expect(payload.ringUntilStartLabel, testL10n.widgetRingUntilStart);
    expect(payload.upNextLabel, testL10n.widgetUpNext);

    final at18 = payload.timelineStates.singleWhere((s) =>
        s.effectiveAtEpochMs ==
        DateTime(2026, 4, 1, 18).millisecondsSinceEpoch);
    expect(at18.upcomingRoutines.map((r) => r.title), ['독서']);
    expect(at18.toJson()['upcomingRoutines'], hasLength(1));
  });

  test('다음 루틴이 없을 때와 iOS 공통 문구는 선택한 언어로 저장한다', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final payload = SystemHomeWidgetTimeline.build(
      now: DateTime(2026, 4, 1, 16),
      l10n: l10n,
      routines: const [],
      logsToday: const [],
    );

    expect(payload.nextRoutineTitle, 'None');
    expect(payload.timelineStates.first.nextRoutineTitle, 'None');
    expect(payload.nextLabel, 'Next');
    expect(payload.refreshHint, l10n.widgetRefreshHint);
  });
}
