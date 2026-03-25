import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/home_models.dart';
import '../../theme/home_theme.dart';

/// Home의 **원형 시간표 영역** — 루틴 목록·현재 시각·활성 루틴만 주입하면 됨.
///
/// - [routines]: 시계 둘레 세그먼트(시작 시각 순). 비어 있으면 아무 것도 그리지 않음.
/// - [currentTime]: 시침·중앙 시각 표시 (24h 기준 hour/minute).
/// - [activeRoutine]: 강조할 루틴 — [RoutineSegment.id]와 id가 같아야 함. null이면 강조 없음.
/// - [centerRoutineName]: 중앙에 표시할 루틴 이름 (시간 슬롯이 없을 때 다음 루틴 등)
class CircularTimetableArea extends StatelessWidget {
  const CircularTimetableArea({
    super.key,
    required this.routines,
    required this.currentTime,
    this.activeRoutine,
    required this.centerRoutineName,
  });

  /// 원형 시간표에 그릴 루틴(세그먼트) 목록
  final List<RoutineSegment> routines;

  /// 현재 시각 (시침 + 중앙 라벨)
  final TimeOfDay currentTime;

  /// 현재 시간대에 해당하면 링에서 강조
  final CurrentRoutine? activeRoutine;

  /// 시계 중앙 라벨 (현재/다음 루틴 이름)
  final String centerRoutineName;

  @override
  Widget build(BuildContext context) {
    if (routines.isEmpty) {
      return const SizedBox.shrink();
    }

    return _CircularTimetableView(
      segments: routines,
      currentHour: currentTime.hour,
      currentMinute: currentTime.minute,
      activeSegmentId: activeRoutine?.id ?? '',
      activeRoutineName: centerRoutineName,
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
    required this.activeRoutineName,
  });

  final List<RoutineSegment> segments;
  final int currentHour;
  final int currentMinute;
  final String activeSegmentId;
  final String activeRoutineName;

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
            final startRad =
                (seg.startMinutesFromMidnight / (24 * 60)) * 2 * math.pi -
                    math.pi / 2;
            final endRad =
                (next.startMinutesFromMidnight / (24 * 60)) * 2 * math.pi -
                    math.pi / 2;
            double mid = (startRad + endRad) / 2;
            if (endRad < startRad) {
              mid = (startRad + endRad + 2 * math.pi) / 2;
              if (mid > math.pi) mid -= 2 * math.pi;
            }
            const midR = 102 / 2;
            final x = 50 + midR * math.cos(mid);
            final y = 50 + midR * math.sin(mid);
            final isActive = seg.id == activeSegmentId;
            final slotW = isActive ? 58.0 : 36.0;
            final slotH = isActive ? 58.0 : 34.0;
            return Positioned(
              left: size * x / 100 - slotW / 2,
              top: size * y / 100 - slotH / 2,
              width: slotW,
              height: slotH,
              child: isActive
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          seg.emoji,
                          style: const TextStyle(fontSize: 22, height: 1),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: HomeTheme.accentPink.withValues(alpha: 0.42),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: HomeTheme.accentPink.withValues(alpha: 0.7),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: HomeTheme.accentPink.withValues(alpha: 0.28),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            seg.label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.15,
                              color: HomeTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Text(
                        seg.emoji,
                        style: TextStyle(
                          fontSize: 17,
                          height: 1,
                          color: HomeTheme.textMuted.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
            );
          }),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${currentHour.toString().padLeft(2, '0')}:${currentMinute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  height: 1.05,
                  color: HomeTheme.textPrimary,
                  shadows: [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.95),
                      blurRadius: 6,
                    ),
                    Shadow(
                      color: HomeTheme.textPrimary.withValues(alpha: 0.12),
                      offset: const Offset(0, 1),
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '지금 루틴',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.35,
                  color: HomeTheme.textMuted.withValues(alpha: 0.88),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                activeRoutineName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HomeTheme.textPrimary,
                ),
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
      var startRad =
          (seg.startMinutesFromMidnight / (24 * 60)) * 2 * math.pi -
              math.pi / 2;
      var endRad =
          (next.startMinutesFromMidnight / (24 * 60)) * 2 * math.pi -
              math.pi / 2;
      var sweep = endRad - startRad;
      if (sweep <= 0) sweep += 2 * math.pi;

      final isActive = seg.id == activeSegmentId;

      if (isActive) {
        final glow = Paint()
          ..color = HomeTheme.accentPink.withValues(alpha: 0.38)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW + 12
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: midR),
          startRad,
          sweep,
          false,
          glow,
        );
      }

      final paint = Paint()
        ..color = seg.color.withValues(alpha: isActive ? 1.0 : 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = isActive ? StrokeCap.round : StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: c, radius: midR),
        startRad,
        sweep,
        false,
        paint,
      );

      if (isActive) {
        final hi = Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: midR),
          startRad,
          sweep,
          false,
          hi,
        );
        final rim = Paint()
          ..color = const Color(0xFFFF8CA8).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: midR + strokeW * 0.35),
          startRad,
          sweep,
          false,
          rim,
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

    const shadowOffset = Offset(0, 1.8);
    final shadowPaint = Paint()
      ..color = const Color(0xFFC75B7E).withValues(alpha: 0.28)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c + shadowOffset, end + shadowOffset, shadowPaint);

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF9EB0), Color(0xFFFF6B9D)],
      ).createShader(Rect.fromPoints(c, end))
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(c, end, paint);

    final rim = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(c, 9.5 * scale, rim);

    final dot = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFB8C6), Color(0xFFFF6B9D)],
      ).createShader(Rect.fromCircle(center: c, radius: 8));
    canvas.drawCircle(c, 7.5 * scale, dot);
  }

  @override
  bool shouldRepaint(covariant _ClockHandPainter oldDelegate) {
    return oldDelegate.hour != hour || oldDelegate.minute != minute;
  }
}
