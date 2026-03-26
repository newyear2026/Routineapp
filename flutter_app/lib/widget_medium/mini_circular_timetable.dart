import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'medium_ring_segment.dart';

/// 미니 **동심원 도넛** 24시간 원형 시간표 — Medium 위젯 전용.
///
/// - 0시 = 12시 방향(위), 시계 방향으로 증가
/// - 외곽 0 / 6 / 12 / 18 시 라벨
/// - [currentTime] 기준 포인터(24시간 각도)
class MiniCircularTimetable extends StatelessWidget {
  const MiniCircularTimetable({
    super.key,
    required this.segments,
    required this.currentTime,
    this.activeSegmentId,
    this.pointerAngleRad,
    this.centerLabel = '현재 시간',
    this.size = 132,
  });

  final List<MediumRingSegment> segments;
  final TimeOfDay currentTime;
  final String? activeSegmentId;
  final double? pointerAngleRad;
  final String centerLabel;
  final double size;

  static double pointerAngleFromTime(TimeOfDay t) {
    final m = t.hour * 60 + t.minute;
    return (m / (24 * 60)) * 2 * math.pi - math.pi / 2;
  }

  @override
  Widget build(BuildContext context) {
    final angle = pointerAngleRad ?? pointerAngleFromTime(currentTime);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _MiniDonutRingPainter(
              segments: segments,
              activeSegmentId: activeSegmentId,
            ),
          ),
          CustomPaint(
            size: Size(size, size),
            painter: _MiniPointerPainter(angleRad: angle),
          ),
          _HourLabels(size: size),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Color(0xFF5C4033),
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                centerLabel,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9A8AAC).withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 외곽 0·6·12·18 시 라벨
class _HourLabels extends StatelessWidget {
  const _HourLabels({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = size / 2;
    final r = size * 0.52;
    const labels = <(int, double)>[
      (0, -math.pi / 2),
      (6, 0),
      (12, math.pi / 2),
      (18, math.pi),
    ];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final (h, ang) in labels)
          Positioned(
            left: c + r * math.cos(ang) - 14,
            top: c + r * math.sin(ang) - 8,
            child: Text(
              '$h시',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF7A6B5A).withValues(alpha: 0.85),
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniDonutRingPainter extends CustomPainter {
  _MiniDonutRingPainter({
    required this.segments,
    required this.activeSegmentId,
  });

  final List<MediumRingSegment> segments;
  final String? activeSegmentId;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 200;
    final innerR = 52 * scale;
    final outerR = 78 * scale;
    final midR = (innerR + outerR) / 2;
    final strokeW = outerR - innerR;

    final track = Paint()
      ..color = const Color(0xFFF0E8E0).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: midR),
      -math.pi / 2,
      2 * math.pi,
      false,
      track,
    );

    for (final seg in segments) {
      final startRad =
          (seg.startMinutesFromMidnight / (24 * 60)) * 2 * math.pi -
              math.pi / 2;
      final sweepRad =
          (seg.sweepMinutes / (24 * 60)) * 2 * math.pi;

      final isActive = activeSegmentId != null && seg.id == activeSegmentId;

      if (isActive) {
        final glow = Paint()
          ..color = const Color(0xFFFF8CA8).withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW + 8
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: midR),
          startRad,
          sweepRad,
          false,
          glow,
        );
      }

      final paint = Paint()
        ..color = seg.color.withValues(alpha: isActive ? 1.0 : 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: c, radius: midR),
        startRad,
        sweepRad,
        false,
        paint,
      );
    }

    final hole = Paint()..color = const Color(0xFFFFF9F5);
    canvas.drawCircle(c, innerR - 1, hole);

    final holeBorder = Paint()
      ..color = const Color(0xFFE8DED6).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(c, innerR - 1, holeBorder);
  }

  @override
  bool shouldRepaint(covariant _MiniDonutRingPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.activeSegmentId != activeSegmentId;
  }
}

class _MiniPointerPainter extends CustomPainter {
  _MiniPointerPainter({required this.angleRad});

  final double angleRad;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 200;
    final innerR = 52 * scale;
    final outerR = 78 * scale;
    final midR = (innerR + outerR) / 2;
    final strokeW = outerR - innerR;

    final r0 = midR - strokeW * 0.42;
    final r1 = outerR + 3 * scale;
    final start = Offset(
      c.dx + r0 * math.cos(angleRad),
      c.dy + r0 * math.sin(angleRad),
    );
    final end = Offset(
      c.dx + r1 * math.cos(angleRad),
      c.dy + r1 * math.sin(angleRad),
    );

    final paint = Paint()
      ..color = const Color(0xFFE07A5F)
      ..strokeWidth = math.max(3.0, 5 * scale)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);

    final dot = Paint()..color = const Color(0xFFE07A5F);
    canvas.drawCircle(end, 3.8 * scale, dot);
  }

  @override
  bool shouldRepaint(covariant _MiniPointerPainter oldDelegate) {
    return oldDelegate.angleRad != angleRad;
  }
}
