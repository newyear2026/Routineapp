import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/home_models.dart';
import '../../theme/home_theme.dart';

/// Home 원형 하루 시간표 — Orbit 스타일 리디자인
class CircularTimetableArea extends StatelessWidget {
  const CircularTimetableArea({
    super.key,
    required this.routines,
    required this.currentTime,
    this.activeRoutine,
    required this.centerRoutineName,
    this.size = 272,
  });

  final List<RoutineSegment> routines;
  final TimeOfDay currentTime;
  final CurrentRoutine? activeRoutine;
  final String centerRoutineName;
  final double size;

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
      size: size,
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
    required this.size,
  });

  final List<RoutineSegment> segments;
  final int currentHour;
  final int currentMinute;
  final int nowMinutesFromMidnight;
  final String activeSegmentId;
  final String activeRoutineName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final timeText =
        '${currentHour.toString().padLeft(2, '0')}:${currentMinute.toString().padLeft(2, '0')}';

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.12,
            child: Container(
              width: size * 0.82,
              height: size * 0.82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.orbitHalo.withValues(alpha: 0.22),
                    AppColors.orbitHalo.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFFFFFEFC),
                  AppColors.orbitSurface,
                  Color(0xFFF4EEF8),
                ],
                stops: [0.08, 0.62, 1],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.84),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orbitPrimary.withValues(alpha: 0.09),
                  blurRadius: 34,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
          ),
          CustomPaint(
            size: Size.square(size),
            painter: _OrbitTimetablePainter(
              segments: segments,
              activeSegmentId: activeSegmentId,
              nowMinutesFromMidnight: nowMinutesFromMidnight,
            ),
          ),
          Container(
            width: size * 0.44,
            height: size * 0.44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.74),
              border: Border.all(
                color: AppColors.orbitBorder.withValues(alpha: 0.9),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.9),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeText,
                  style: TextStyle(
                    fontSize: size >= 300 ? 40 : 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.6,
                    height: 1.0,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orbitSurfaceSoft.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '지금',
                    style: TextStyle(
                      color: HomeTheme.textMuted.withValues(alpha: 0.84),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.orbitPrimaryGradient,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.orbitPrimary.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    activeRoutineName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
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

class _OrbitTimetablePainter extends CustomPainter {
  _OrbitTimetablePainter({
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

  double _segmentSweepRad(RoutineSegment segment) {
    final sweepMinutes =
        segment.endMinutesFromMidnight - segment.startMinutesFromMidnight;
    if (sweepMinutes <= 0) return 0;
    return (sweepMinutes / (24 * 60)) * 2 * math.pi;
  }

  void _paintOuterLabel(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    String text,
    double scale,
  ) {
    if (text.isEmpty) return;

    final position = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: AppColors.textStrong.withValues(alpha: 0.82),
          fontSize: 10.5 * scale,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.15,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: 56 * scale);
    tp.paint(
      canvas,
      Offset(position.dx - tp.width / 2, position.dy - tp.height / 2),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 292;
    final orbitRadius = size.width * 0.34;
    final baseStroke = 22 * scale;
    final activeStroke = 28 * scale;
    final backgroundStroke = 18 * scale;
    const gapRad = 0.018;

    final backTrack = Paint()
      ..color = AppColors.orbitBorder.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = backgroundStroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: orbitRadius),
      -math.pi / 2,
      math.pi * 2,
      false,
      backTrack,
    );

    for (var h = 0; h < 24; h++) {
      final angle = _minutesToRad(h * 60);
      final tickLength = h % 6 == 0 ? 11 * scale : 6 * scale;
      final inner = Offset(
        center.dx +
            math.cos(angle) * (orbitRadius - backgroundStroke / 2 - 10 * scale),
        center.dy +
            math.sin(angle) * (orbitRadius - backgroundStroke / 2 - 10 * scale),
      );
      final outer = Offset(
        center.dx +
            math.cos(angle) *
                (orbitRadius - backgroundStroke / 2 - 10 * scale - tickLength),
        center.dy +
            math.sin(angle) *
                (orbitRadius - backgroundStroke / 2 - 10 * scale - tickLength),
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color =
              AppColors.textMuted.withValues(alpha: h % 6 == 0 ? 0.34 : 0.18)
          ..strokeWidth = h % 6 == 0 ? 2.4 * scale : 1.3 * scale
          ..strokeCap = StrokeCap.round,
      );
    }

    for (final segment in segments) {
      final sweep = _segmentSweepRad(segment);
      if (sweep <= 0) continue;

      final isActive = segment.id == activeSegmentId;
      final stroke = isActive ? activeStroke : baseStroke;
      final start = _minutesToRad(segment.startMinutesFromMidnight) + gapRad;
      final safeSweep = math.max(0.02, sweep - gapRad * 2);
      final segmentRect = Rect.fromCircle(
        center: center,
        radius: orbitRadius + (isActive ? 4 * scale : 0),
      );

      if (isActive) {
        canvas.drawArc(
          segmentRect,
          start,
          safeSweep,
          false,
          Paint()
            ..color = segment.color.withValues(alpha: 0.22)
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke + 10 * scale
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }

      canvas.drawArc(
        segmentRect,
        start,
        safeSweep,
        false,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Color.lerp(segment.color, Colors.white, 0.08)!,
              Color.lerp(
                  segment.color, AppColors.textStrong, isActive ? 0.08 : 0.02)!,
            ],
          ).createShader(segmentRect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );

      final mid = _minutesToRad(
        segment.startMinutesFromMidnight +
            ((segment.endMinutesFromMidnight -
                    segment.startMinutesFromMidnight) ~/
                2),
      );
      if (safeSweep > 0.34) {
        _paintOuterLabel(
          canvas,
          center,
          orbitRadius + stroke / 2 + 22 * scale,
          mid,
          segment.label,
          scale,
        );
      }
    }

    _paintOuterLabel(
        canvas, center, orbitRadius + 34 * scale, -math.pi / 2, '00', scale);
    _paintOuterLabel(canvas, center, orbitRadius + 34 * scale, 0, '06', scale);
    _paintOuterLabel(
        canvas, center, orbitRadius + 34 * scale, math.pi / 2, '12', scale);
    _paintOuterLabel(
        canvas, center, orbitRadius + 34 * scale, math.pi, '18', scale);

    final nowRad = _minutesToRad(nowMinutesFromMidnight);
    final nowCenter = Offset(
      center.dx + math.cos(nowRad) * (orbitRadius + 4 * scale),
      center.dy + math.sin(nowRad) * (orbitRadius + 4 * scale),
    );

    canvas.drawCircle(
      nowCenter,
      17 * scale,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.orbitAccent.withValues(alpha: 0.36),
            AppColors.orbitAccent.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromCircle(center: nowCenter, radius: 17 * scale)),
    );
    canvas.drawCircle(
      nowCenter,
      6.8 * scale,
      Paint()
        ..shader = AppColors.orbitWarmGradient.createShader(
          Rect.fromCircle(center: nowCenter, radius: 8 * scale),
        ),
    );
    canvas.drawCircle(
      nowCenter,
      2.8 * scale,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitTimetablePainter oldDelegate) {
    return !_sameSegments(oldDelegate.segments, segments) ||
        oldDelegate.activeSegmentId != activeSegmentId ||
        oldDelegate.nowMinutesFromMidnight != nowMinutesFromMidnight;
  }

  bool _sameSegments(List<RoutineSegment> a, List<RoutineSegment> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if (left.id != right.id ||
          left.startMinutesFromMidnight != right.startMinutesFromMidnight ||
          left.endMinutesFromMidnight != right.endMinutesFromMidnight ||
          left.label != right.label ||
          left.emoji != right.emoji ||
          left.color.toARGB32() != right.color.toARGB32()) {
        return false;
      }
    }
    return true;
  }
}
