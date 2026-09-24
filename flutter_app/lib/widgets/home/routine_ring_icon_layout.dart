import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/home_models.dart';

/// 원형 시간표의 색상 호 안쪽에 올릴 아이콘 위치.
class RoutineRingIconPlacement {
  const RoutineRingIconPlacement({
    required this.segment,
    required this.center,
    required this.size,
  });

  final RoutineSegment segment;
  final Offset center;
  final double size;

  Rect get bounds => Rect.fromCenter(center: center, width: size, height: size);
}

abstract final class RoutineRingIconLayout {
  /// 매우 짧은 구간에는 배지가 시간 길이보다 커 보이므로 색상 호만 남긴다.
  static const minDurationMinutes = 30;

  static List<RoutineRingIconPlacement> arrange({
    required List<RoutineSegment> segments,
    required double dialSize,
    required String activeSegmentId,
  }) {
    final badgeSize = (dialSize * 0.095).clamp(20.0, 27.0).toDouble();
    final badgeRadius = dialSize * 0.305;
    final candidates = segments.where((segment) {
      return segment.iconId != null &&
          segment.endMinutesFromMidnight - segment.startMinutesFromMidnight >=
              minDurationMinutes;
    }).toList()
      ..sort((a, b) {
        final aActive = a.id == activeSegmentId;
        final bActive = b.id == activeSegmentId;
        if (aActive != bActive) return aActive ? -1 : 1;
        final aDuration = a.endMinutesFromMidnight - a.startMinutesFromMidnight;
        final bDuration = b.endMinutesFromMidnight - b.startMinutesFromMidnight;
        final durationOrder = bDuration.compareTo(aDuration);
        if (durationOrder != 0) return durationOrder;
        return a.startMinutesFromMidnight.compareTo(b.startMinutesFromMidnight);
      });

    final placed = <RoutineRingIconPlacement>[];
    for (final segment in candidates) {
      final midpoint =
          (segment.startMinutesFromMidnight + segment.endMinutesFromMidnight) /
              2;
      final angle = midpoint / (24 * 60) * 2 * math.pi - math.pi / 2;
      final center = Offset(
        dialSize / 2 + math.cos(angle) * badgeRadius,
        dialSize / 2 + math.sin(angle) * badgeRadius,
      );
      final candidate = RoutineRingIconPlacement(
        segment: segment,
        center: center,
        size: badgeSize,
      );
      if (placed
          .any((other) => candidate.bounds.inflate(3).overlaps(other.bounds))) {
        continue;
      }
      placed.add(candidate);
    }
    return placed;
  }
}
