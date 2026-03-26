import 'package:flutter/material.dart';

import 'medium_ring_segment.dart';

/// iOS Medium 위젯(스타일)용 ViewModel — [HomeMediumWidgetSelector]에서 주입.
///
/// [pointerAngleRad]는 선택 필드: null이면 [currentTime]으로 24시간 각도 계산.
class HomeMediumWidgetViewModel {
  const HomeMediumWidgetViewModel({
    required this.headerTitle,
    required this.subtitle,
    required this.currentRoutineTitle,
    required this.currentRoutineIconEmoji,
    required this.currentRoutineTimeRange,
    required this.currentRoutineStatusLabel,
    required this.nextRoutineLine,
    required this.currentTime,
    required this.centerTimeLabel,
    required this.ringSegments,
    this.activeSegmentId,
    this.pointerAngleRad,
  });

  final String headerTitle;
  final String subtitle;

  final String currentRoutineTitle;
  final String currentRoutineIconEmoji;
  final String currentRoutineTimeRange;
  final String currentRoutineStatusLabel;

  /// 예: `다음: search (21:00)`
  final String nextRoutineLine;

  final TimeOfDay currentTime;
  final String centerTimeLabel;

  final List<MediumRingSegment> ringSegments;
  final String? activeSegmentId;

  /// 24시간 시계 기준(라디안). 0시 방향이 위(-π/2)와 일치하도록 외부에서 줄 수 있음.
  final double? pointerAngleRad;

  /// 디자인 시안용 더미 — 실제 앱에서는 [HomeMediumWidgetSelector] 사용.
  static HomeMediumWidgetViewModel dummy() {
    return HomeMediumWidgetViewModel(
      headerTitle: '하루 루틴 시간표',
      subtitle: '오늘 루틴 진행 중',
      currentRoutineTitle: 'Game',
      currentRoutineIconEmoji: '📌',
      currentRoutineTimeRange: '21:00 - 23:00',
      currentRoutineStatusLabel: '진행 중',
      nextRoutineLine: '다음: search (21:00)',
      currentTime: const TimeOfDay(hour: 21, minute: 30),
      centerTimeLabel: '현재 시간',
      activeSegmentId: 'seg_game',
      ringSegments: [
        MediumRingSegment(
          id: 'seg_a',
          startMinutesFromMidnight: 6 * 60,
          sweepMinutes: 4 * 60,
          color: const Color(0xFFFFD4E0),
        ),
        MediumRingSegment(
          id: 'seg_b',
          startMinutesFromMidnight: 10 * 60,
          sweepMinutes: 4 * 60,
          color: const Color(0xFFFFE9D4),
        ),
        MediumRingSegment(
          id: 'seg_c',
          startMinutesFromMidnight: 14 * 60,
          sweepMinutes: 4 * 60,
          color: const Color(0xFFE8DDFA),
        ),
        MediumRingSegment(
          id: 'seg_d',
          startMinutesFromMidnight: 18 * 60,
          sweepMinutes: 3 * 60,
          color: const Color(0xFFC8E6D4).withValues(alpha: 0.95),
        ),
        MediumRingSegment(
          id: 'seg_game',
          startMinutesFromMidnight: 21 * 60,
          sweepMinutes: 2 * 60,
          color: const Color(0xFFFFB8C6),
        ),
        MediumRingSegment(
          id: 'seg_f',
          startMinutesFromMidnight: 23 * 60,
          sweepMinutes: 7 * 60,
          color: const Color(0xFFD4E4FF),
        ),
      ],
    );
  }
}
