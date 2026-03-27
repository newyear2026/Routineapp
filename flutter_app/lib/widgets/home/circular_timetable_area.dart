import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/home_models.dart';
import '../../theme/home_theme.dart';

/// Home의 **원형 시간표 영역** — 시계 바늘이 아닌 하루 루틴 시간표 UI.
///
/// - [routines]: 시계 둘레 세그먼트(시작 시각 순). 비어 있으면 아무 것도 그리지 않음.
/// - [currentTime]: 중앙 시각 텍스트 및 링 위 «지금» 위치 점.
/// - [activeRoutine]: 강조할 루틴 — [RoutineSegment.id]와 id가 같아야 함. null이면 강조 없음.
/// - [centerRoutineName]: 중앙에 표시할 현재 루틴 이름
class CircularTimetableArea extends StatelessWidget {
  const CircularTimetableArea({
    super.key,
    required this.routines,
    required this.currentTime,
    this.activeRoutine,
    required this.centerRoutineName,
  });

  final List<RoutineSegment> routines;
  final TimeOfDay currentTime;
  final CurrentRoutine? activeRoutine;
  final String centerRoutineName;

  @override
  Widget build(BuildContext context) {
    if (routines.isEmpty) {
      return const SizedBox.shrink();
    }

    final nowMin = currentTime.hour * 60 + currentTime.minute;

    return _CircularTimetableView(
      segments: routines,
      currentHour: currentTime.hour,
      currentMinute: currentTime.minute,
      nowMinutesFromMidnight: nowMin,
      activeSegmentId: activeRoutine?.id ?? '',
      activeRoutineName: centerRoutineName,
    );
  }
}

class _CircularTimetableView extends StatelessWidget {
  const _CircularTimetableView({
    required this.segments,
    required this.currentHour,
    required this.currentMinute,
    required this.nowMinutesFromMidnight,
    required this.activeSegmentId,
    required this.activeRoutineName,
  });

  final List<RoutineSegment> segments;
  final int currentHour;
  final int currentMinute;
  final int nowMinutesFromMidnight;
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
              nowMinutesFromMidnight: nowMinutesFromMidnight,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: HomeTheme.accentPink.withValues(alpha: 0.42),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  HomeTheme.accentPink.withValues(alpha: 0.7),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: HomeTheme.accentPink.withValues(
                                  alpha: 0.28,
                                ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${currentHour.toString().padLeft(2, '0')}:${currentMinute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                    height: 1.05,
                    color: HomeTheme.textPrimary,
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.95),
                        blurRadius: 6,
                      ),
                      Shadow(
                        color: HomeTheme.textPrimary.withValues(alpha: 0.1),
                        offset: const Offset(0, 1),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '지금',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: HomeTheme.textMuted.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activeRoutineName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: HomeTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 동심원 도넛 + 시간 가이드 + 루틴 구간 + 현재 시각 점 (긴 바늘 없음)
class _TimetableRingPainter extends CustomPainter {
  _TimetableRingPainter({
    required this.segments,
    required this.activeSegmentId,
    required this.nowMinutesFromMidnight,
  });

  final List<RoutineSegment> segments;
  final String activeSegmentId;
  final int nowMinutesFromMidnight;

  double _minutesToRad(int minutes) {
    return (minutes / (24 * 60)) * 2 * math.pi - math.pi / 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 200;
    final innerR = 58 * scale;
    final outerR = 87 * scale;
    final midR = (innerR + outerR) / 2;
    final strokeW = outerR - innerR;
    final ringInner = midR - strokeW / 2;
    final ringOuter = midR + strokeW / 2;
    final centerHoleR = 50 * scale;

    final glow = Paint()
      ..color = const Color(0xFFE8DDFA).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(c, outerR + 8, glow);

    final bg = Paint()..color = const Color(0xFFFFF9F5);
    canvas.drawCircle(c, outerR + 4, bg);

    // —— 시간 가이드: 중앙 홀 ~ 도넛 안쪽 사이 (얇은 방사선, 24h)
    for (var h = 0; h < 24; h++) {
      final angle = _minutesToRad(h * 60);
      final isMajor = h == 0 || h == 6 || h == 12 || h == 18;
      final paint = Paint()
        ..color = const Color(0xFFB8A4C9).withValues(
          alpha: isMajor ? 0.38 : 0.14,
        )
        ..strokeWidth = isMajor ? 1.25 * scale : 0.75 * scale
        ..strokeCap = StrokeCap.round;
      final r0 = centerHoleR + 2 * scale;
      final r1 = ringInner - 1.5 * scale;
      final start = Offset(
        c.dx + r0 * math.cos(angle),
        c.dy + r0 * math.sin(angle),
      );
      final end = Offset(
        c.dx + r1 * math.cos(angle),
        c.dy + r1 * math.sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }

    // —— 루틴 구간 호 (기존 + 경계 강조)
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final next = segments[(i + 1) % segments.length];
      var startRad = (seg.startMinutesFromMidnight / (24 * 60)) * 2 * math.pi -
          math.pi / 2;
      var endRad = (next.startMinutesFromMidnight / (24 * 60)) * 2 * math.pi -
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
        ..color = seg.color.withValues(alpha: isActive ? 1.0 : 0.52)
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

      // 루틴 시작 경계선 (시간 가이드보다 선명)
      final boundaryPaint = Paint()
        ..color = seg.color.withValues(alpha: isActive ? 0.95 : 0.72)
        ..strokeWidth = isActive ? 2.8 * scale : 2.0 * scale
        ..strokeCap = StrokeCap.round;
      final b0 = Offset(
        c.dx + ringInner * math.cos(startRad),
        c.dy + ringInner * math.sin(startRad),
      );
      final b1 = Offset(
        c.dx + ringOuter * math.cos(startRad),
        c.dy + ringOuter * math.sin(startRad),
      );
      canvas.drawLine(b0, b1, boundaryPaint);
    }

    // —— 현재 시각: 링 바깥쪽 작은 점 (긴 바늘 없음)
    final nowRad = _minutesToRad(nowMinutesFromMidnight);
    final dotR = ringOuter + 3.2 * scale;
    final dotCenter = Offset(
      c.dx + dotR * math.cos(nowRad),
      c.dy + dotR * math.sin(nowRad),
    );
    final dotGlow = Paint()
      ..color = const Color(0xFFFFB8C6).withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(dotCenter, 7 * scale, dotGlow);
    final dotFill = Paint()
      ..color = const Color(0xFFE07A5F).withValues(alpha: 0.92);
    canvas.drawCircle(dotCenter, 4.2 * scale, dotFill);
    final dotRim = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(dotCenter, 4.2 * scale, dotRim);

    final centerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(c, centerHoleR, centerPaint);
    final centerBorder = Paint()
      ..color = const Color(0xFFB8A4C9).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(c, centerHoleR, centerBorder);
  }

  @override
  bool shouldRepaint(covariant _TimetableRingPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.activeSegmentId != activeSegmentId ||
        oldDelegate.nowMinutesFromMidnight != nowMinutesFromMidnight;
  }
}
