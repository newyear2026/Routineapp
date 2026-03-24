import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/home_models.dart';
import '../../theme/home_theme.dart';

/// Home의 **원형 시간표 영역** — 루틴 목록·현재 시각·활성 루틴만 주입하면 됨.
///
/// - [routines]: 시계 둘레 세그먼트(시작 시각 순). 비어 있으면 아무 것도 그리지 않음.
/// - [currentTime]: 시침·중앙 시각 표시 (24h 기준 hour/minute).
/// - [activeRoutine]: 강조할 루틴 — [RoutineSegment.id]와 [CurrentRoutine.id]가 같아야 같은 조각이 강조됨.
class CircularTimetableArea extends StatelessWidget {
  const CircularTimetableArea({
    super.key,
    required this.routines,
    required this.currentTime,
    required this.activeRoutine,
  });

  /// 원형 시간표에 그릴 루틴(세그먼트) 목록
  final List<RoutineSegment> routines;

  /// 현재 시각 (시침 + 중앙 라벨)
  final TimeOfDay currentTime;

  /// 현재 활성 루틴 (세그먼트 id와 매칭)
  final CurrentRoutine activeRoutine;

  @override
  Widget build(BuildContext context) {
    if (routines.isEmpty) {
      return const SizedBox.shrink();
    }

    return _CircularTimetableView(
      segments: routines,
      currentHour: currentTime.hour,
      currentMinute: currentTime.minute,
      activeSegmentId: activeRoutine.id,
    );
  }
}

/// 내부 구현 — [CircularTimetableArea]에서만 사용
class _CircularTimetableView extends StatelessWidget {
  const _CircularTimetableView({
    required this.segments,
    required this.currentHour,
    required this.currentMinute,
    required this.activeSegmentId,
  });

  final List<RoutineSegment> segments;
  final int currentHour;
  final int currentMinute;
  final String activeSegmentId;

  @override
  Widget build(BuildContext context) {
    const size = 320.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: _TimetableRingPainter(
              segments: segments,
              activeSegmentId: activeSegmentId,
            ),
          ),
          ...segments.asMap().entries.map((e) {
            final i = e.key;
            final seg = e.value;
            final next = segments[(i + 1) % segments.length];
            final startRad = (seg.startHour / 24) * 2 * math.pi - math.pi / 2;
            final endRad = (next.startHour / 24) * 2 * math.pi - math.pi / 2;
            double mid = (startRad + endRad) / 2;
            if (endRad < startRad) {
              mid = (startRad + endRad + 2 * math.pi) / 2;
              if (mid > math.pi) mid -= 2 * math.pi;
            }
            const midR = 102 / 2;
            final x = 50 + midR * math.cos(mid);
            final y = 50 + midR * math.sin(mid);
            final isActive = seg.id == activeSegmentId;
            return Positioned(
              left: size * x / 100 - 24,
              top: size * y / 100 - 24,
              width: 48,
              height: 48,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    seg.emoji,
                    style: TextStyle(fontSize: isActive ? 22 : 18),
                  ),
                  Text(
                    seg.label,
                    style: TextStyle(
                      fontSize: isActive ? 11 : 10,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? HomeTheme.textPrimary : HomeTheme.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${currentHour.toString().padLeft(2, '0')}:${currentMinute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: HomeTheme.textPrimary,
                ),
              ),
              const Text(
                '현재 시간',
                style: TextStyle(fontSize: 11, color: HomeTheme.textMuted),
              ),
            ],
          ),
          _ClockHandLayer(
            hour: currentHour,
            minute: currentMinute,
            size: size,
          ),
        ],
      ),
    );
  }
}

class _TimetableRingPainter extends CustomPainter {
  _TimetableRingPainter({
    required this.segments,
    required this.activeSegmentId,
  });

  final List<RoutineSegment> segments;
  final String activeSegmentId;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 200;
    final innerR = 58 * scale;
    final outerR = 87 * scale;
    final midR = (innerR + outerR) / 2;
    final strokeW = outerR - innerR;

    final glow = Paint()
      ..color = const Color(0xFFE8DDFA).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(c, outerR + 8, glow);

    final bg = Paint()..color = const Color(0xFFFFF9F5);
    canvas.drawCircle(c, outerR + 4, bg);

    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final next = segments[(i + 1) % segments.length];
      var startRad = (seg.startHour / 24) * 2 * math.pi - math.pi / 2;
      var endRad = (next.startHour / 24) * 2 * math.pi - math.pi / 2;
      var sweep = endRad - startRad;
      if (sweep <= 0) sweep += 2 * math.pi;

      final isActive = seg.id == activeSegmentId;
      final paint = Paint()
        ..color = seg.color.withValues(alpha: isActive ? 0.95 : 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: c, radius: midR),
        startRad,
        sweep,
        false,
        paint,
      );

      if (isActive) {
        final hi = Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: midR),
          startRad,
          sweep,
          false,
          hi,
        );
      }
    }

    final centerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(c, 50 * scale, centerPaint);
    final centerBorder = Paint()
      ..color = const Color(0xFFB8A4C9).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(c, 50 * scale, centerBorder);
  }

  @override
  bool shouldRepaint(covariant _TimetableRingPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.activeSegmentId != activeSegmentId;
  }
}

class _ClockHandLayer extends StatelessWidget {
  const _ClockHandLayer({
    required this.hour,
    required this.minute,
    required this.size,
  });

  final int hour;
  final int minute;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ClockHandPainter(hour: hour, minute: minute),
    );
  }
}

class _ClockHandPainter extends CustomPainter {
  _ClockHandPainter({required this.hour, required this.minute});

  final int hour;
  final int minute;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 320;
    final len = 55 * scale;
    final angle = ((hour % 12) + minute / 60) / 12 * 2 * math.pi - math.pi / 2;
    final end = Offset(
      c.dx + len * math.cos(angle),
      c.dy + len * math.sin(angle),
    );

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFB8C6), Color(0xFFFF8CA8)],
      ).createShader(Rect.fromPoints(c, end))
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(c, end, paint);

    final dot = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFB8C6), Color(0xFFFF8CA8)],
      ).createShader(Rect.fromCircle(center: c, radius: 8));
    canvas.drawCircle(c, 8 * scale, dot);
  }

  @override
  bool shouldRepaint(covariant _ClockHandPainter oldDelegate) {
    return oldDelegate.hour != hour || oldDelegate.minute != minute;
  }
}
