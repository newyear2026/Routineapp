import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

import '../domain/models/routine_icon_id.dart';
import '../theme/routine_palette.dart';
import 'medium_ring_segment.dart';
import 'widget_timeline_item.dart';

/// iOS Medium 위젯(스타일)용 ViewModel — [HomeMediumWidgetSelector]에서 주입.
///
/// [pointerAngleRad]는 선택 필드: null이면 [currentTime]으로 24시간 각도 계산.
class HomeMediumWidgetViewModel {
  const HomeMediumWidgetViewModel({
    required this.currentRoutineTitle,
    required this.currentRoutineTimingHint,
    required this.currentRoutineStatusLabel,
    required this.nextRoutineTitle,
    required this.nextRoutineTime,
    required this.currentTime,
    required this.centerTimeLabel,
    required this.ringSegments,
    this.currentRoutineIconId = RoutineIconId.coffee,
    this.currentRoutineColor = RoutinePalette.blue,
    this.currentRoutineTimeRange = '',
    this.remainingDuration = '',
    this.remainingLabel = '',
    this.completeLabel = '',
    this.completeActionUri,
    this.activeSegmentId,
    this.pointerAngleRad,
    this.timelineItems = const [],
    this.timelineNowEpochMs = 0,
  });

  final String remainingDuration;
  final String remainingLabel;
  final String completeLabel;
  final String? completeActionUri;
  final List<WidgetTimelineItem> timelineItems;
  final int timelineNowEpochMs;
  bool get canComplete => completeActionUri != null;

  final String currentRoutineTitle;
  final String currentRoutineTimingHint;
  final String currentRoutineStatusLabel;
  final RoutineIconId currentRoutineIconId;
  final Color currentRoutineColor;
  final String currentRoutineTimeRange;

  final String nextRoutineTitle;
  final String nextRoutineTime;

  final TimeOfDay currentTime;
  final String centerTimeLabel;

  final List<MediumRingSegment> ringSegments;
  final String? activeSegmentId;

  /// 24시간 시계 기준(라디안). 0시 방향이 위(-π/2)와 일치하도록 외부에서 줄 수 있음.
  final double? pointerAngleRad;

  /// 미리보기용 더미 — 실제 앱에서는 [HomeMediumWidgetSelector] 사용.
  ///
  /// 색은 앱이 실제로 쓰는 [RoutinePalette]에서 가져온다. 더미만 다른 파스텔을
  /// 쓰면 미리보기가 실물과 다른 인상을 준다.
  static HomeMediumWidgetViewModel dummy(AppLocalizations l10n,
      {bool completed = false}) {
    return HomeMediumWidgetViewModel(
      remainingDuration: completed ? '' : l10n.durationMinutes(46),
      remainingLabel: l10n.widgetRingUntilEnd,
      completeLabel: l10n.widgetComplete,
      completeActionUri: completed ? null : 'loopet-widget://sample',
      currentRoutineTitle: l10n.catalogBreak,
      currentRoutineTimingHint:
          completed ? '' : l10n.timingUntilEnd(l10n.durationMinutes(46)),
      currentRoutineStatusLabel:
          completed ? l10n.statusCompleted : l10n.statusInProgress,
      currentRoutineIconId: RoutineIconId.coffee,
      currentRoutineColor: RoutinePalette.blue,
      currentRoutineTimeRange: '15:00-16:00',
      nextRoutineTitle: l10n.catalogDinner,
      nextRoutineTime: '18:00',
      currentTime: const TimeOfDay(hour: 15, minute: 14),
      timelineNowEpochMs: DateTime(2000, 1, 1, 15, 14).millisecondsSinceEpoch,
      timelineItems: [
        WidgetTimelineItem(
            id: 'seg_rest',
            title: l10n.catalogBreak,
            time: '15:00',
            startEpochMs: DateTime(2000, 1, 1, 15).millisecondsSinceEpoch),
        WidgetTimelineItem(
            id: 'seg_dinner',
            title: l10n.catalogDinner,
            time: '18:00',
            startEpochMs: DateTime(2000, 1, 1, 18).millisecondsSinceEpoch),
        WidgetTimelineItem(
            id: 'seg_sleep',
            title: l10n.catalogSleep,
            time: '23:00',
            startEpochMs: DateTime(2000, 1, 1, 23).millisecondsSinceEpoch),
      ],
      centerTimeLabel: l10n.commonNow,
      activeSegmentId: 'seg_rest',
      ringSegments: const [
        MediumRingSegment(
          id: 'seg_wake',
          startMinutesFromMidnight: 7 * 60,
          sweepMinutes: 60,
          color: RoutinePalette.coral,
        ),
        MediumRingSegment(
          id: 'seg_focus',
          startMinutesFromMidnight: 10 * 60,
          sweepMinutes: 2 * 60,
          color: RoutinePalette.lavender,
        ),
        MediumRingSegment(
          id: 'seg_lunch',
          startMinutesFromMidnight: 12 * 60,
          sweepMinutes: 60,
          color: RoutinePalette.amber,
        ),
        MediumRingSegment(
          id: 'seg_rest',
          startMinutesFromMidnight: 15 * 60,
          sweepMinutes: 60,
          color: RoutinePalette.blue,
        ),
        MediumRingSegment(
          id: 'seg_dinner',
          startMinutesFromMidnight: 18 * 60,
          sweepMinutes: 60,
          color: RoutinePalette.coral,
        ),
        MediumRingSegment(
          id: 'seg_sleep',
          startMinutesFromMidnight: 23 * 60,
          sweepMinutes: 60,
          color: RoutinePalette.lavender,
        ),
      ],
    );
  }
}
