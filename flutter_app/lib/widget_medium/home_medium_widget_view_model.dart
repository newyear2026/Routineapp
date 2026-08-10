import 'package:flutter/material.dart';

import '../theme/routine_palette.dart';
import 'medium_ring_segment.dart';

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
    this.activeSegmentId,
    this.pointerAngleRad,
  });

  final String currentRoutineTitle;
  final String currentRoutineTimingHint;
  final String currentRoutineStatusLabel;

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
  static HomeMediumWidgetViewModel dummy() {
    return const HomeMediumWidgetViewModel(
      currentRoutineTitle: '저녁식사',
      currentRoutineTimingHint: '종료까지 58분 남음',
      currentRoutineStatusLabel: '진행 중',
      nextRoutineTitle: '취침',
      nextRoutineTime: '23:00',
      currentTime: TimeOfDay(hour: 18, minute: 2),
      centerTimeLabel: '지금',
      activeSegmentId: 'seg_dinner',
      ringSegments: [
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
