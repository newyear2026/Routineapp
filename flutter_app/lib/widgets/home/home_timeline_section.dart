import 'package:flutter/material.dart';

import '../../models/home_models.dart';
import '../../theme/home_theme.dart';
import 'circular_timetable_area.dart';

/// 원형 시간표 영역 — 데이터만 받아 표시 (계산 없음)
class HomeTimelineSection extends StatelessWidget {
  const HomeTimelineSection({
    super.key,
    required this.segments,
    required this.clockTime,
    required this.centerRoutineName,
    required this.activeRoutineForRing,
    required this.isEmpty,
  });

  final List<RoutineSegment> segments;
  final TimeOfDay clockTime;
  final String centerRoutineName;
  final CurrentRoutine? activeRoutineForRing;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    if (isEmpty || segments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          '오늘 표시할 루틴이 없어요.\n루틴을 추가해 보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: HomeTheme.textMuted.withValues(alpha: 0.9),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      );
    }

    return CircularTimetableArea(
      routines: segments,
      currentTime: clockTime,
      activeRoutine: activeRoutineForRing,
      centerRoutineName: centerRoutineName,
    );
  }
}
