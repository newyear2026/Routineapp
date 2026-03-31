import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/home_models.dart';
import '../../theme/home_theme.dart';

/// Home **원형 하루 시간표** — 도넛형 조각 + 흰색 구간 경계 + 현재 시각 바늘.
///
/// - [routines]: 시작 시각 순 세그먼트
/// - [currentTime]: 중앙 시각 및 바늘 각도
/// - [activeRoutine]: 강조 구간([RoutineSegment.id] 일치)
/// - [centerRoutineName]: 중앙에 표시할 루틴 이름
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
            painter: _PieTimetablePainter(
              segments: segments,
              activeSegmentId: activeSegmentId,
              nowMinutesFromMidnight: nowMinutesFromMidnight,
            ),
          ),
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

/// 참고 UI: 채워진 도넛 조각, **흰색** 구간 경계, 바깥 12·6 눈금, 흰색 현재 시각 바늘.
class _PieTimetablePainter extends CustomPainter {
  _PieTimetablePainter({
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

  static void _addAnnulusSector(
    Path path,
    Offset c,
    double rInner,
    double rOuter,
    double startRad,
    double sweep,
  ) {
    final endRad = startRad + sweep;
    path.moveTo(
      c.dx + rInner * math.cos(startRad),
      c.dy + rInner * math.sin(startRad),
    );
    path.lineTo(
      c.dx + rOuter * math.cos(startRad),
      c.dy + rOuter * math.sin(startRad),
    );
    path.arcTo(
      Rect.fromCircle(center: c, radius: rOuter),
      startRad,
      sweep,
      false,
    );
    path.lineTo(
      c.dx + rInner * math.cos(endRad),
      c.dy + rInner * math.sin(endRad),
    );
    path.arcTo(
      Rect.fromCircle(center: c, radius: rInner),
      endRad,
      -sweep,
      false,
    );
    path.close();
  }

  void _drawWhiteBoundary(
    Canvas canvas,
    Offset c,
    double angleRad,
    double rInner,
    double rOuter,
    double scale, {
    required bool emphasis,
  }) {
    final cos = math.cos(angleRad);
    final sin = math.sin(angleRad);
    final inner = Offset(c.dx + rInner * cos, c.dy + rInner * sin);
    final outer = Offset(c.dx + rOuter * cos, c.dy + rOuter * sin);
    final w = (emphasis ? 2.85 : 2.0) * scale;
    final p = Paint()
      ..color = Colors.white.withValues(alpha: emphasis ? 0.98 : 0.9)
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (emphasis) {
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.22)
          ..strokeWidth = w + 3 * scale
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
    canvas.drawLine(inner, outer, p);
  }

  void _paintSegmentLabel(
    Canvas canvas,
    Offset c,
    double midRad,
    double rMid,
    String text,
    double sweepRad,
    double scale,
  ) {
    if (text.isEmpty) return;
    final sweepDeg = sweepRad.abs() * 180 / math.pi;
    final useRadial = sweepDeg < 16;
    final fontSize =
        (sweepDeg < 12 ? 8.5 : (sweepDeg < 28 ? 9.5 : 11.0)) * scale;

    final arcChord = rMid * sweepRad.abs();
    final maxW = math.min(arcChord * 0.92, 72 * scale);

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.96),
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1.1,
          letterSpacing: -0.2,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 2,
              offset: const Offset(0, 0.5),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: useRadial ? 3 : 2,
      ellipsis: '…',
      textAlign: TextAlign.center,
    );
    tp.layout(maxWidth: maxW);

    final ox = c.dx + rMid * math.cos(midRad);
    final oy = c.dy + rMid * math.sin(midRad);
    canvas.save();
    canvas.translate(ox, oy);

    /// 좁은 조각: 반지름 방향 정렬, 넓은 조각: 접선(가로에 가깝게) 정렬
    canvas.rotate(useRadial ? midRad : midRad + math.pi / 2);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  void _paintCornerHour(
    Canvas canvas,
    Offset c,
    double outerR,
    double scale,
    double angleRad,
    String primary,
    String? secondary,
  ) {
    final r = outerR + 20 * scale;
    final ox = c.dx + r * math.cos(angleRad);
    final oy = c.dy + r * math.sin(angleRad);

    final children = <InlineSpan>[
      TextSpan(
        text: primary,
        style: TextStyle(
          color: const Color(0xFF6B6570).withValues(alpha: 0.88),
          fontSize: 13 * scale,
          fontWeight: FontWeight.w700,
          height: 1.05,
        ),
      ),
      if (secondary != null)
        TextSpan(
          text: '\n$secondary',
          style: TextStyle(
            color: const Color(0xFF6B6570).withValues(alpha: 0.78),
            fontSize: 11 * scale,
            height: 1.1,
          ),
        ),
    ];

    final tp = TextPainter(
      text: TextSpan(children: children),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(ox - tp.width / 2, oy - tp.height / 2),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 200;

    /// 링 반경 (200 기준 설계 → 320에서 scale)
    final centerHoleR = 44 * scale;
    final ringOuter = 91 * scale;

    final dialShadow = Paint()
      ..color = const Color(0xFFC5C5CE).withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(c, ringOuter + 5 * scale, dialShadow);

    final dialRim = Paint()
      ..color = const Color(0xFFE6E6EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * scale;
    canvas.drawCircle(c, ringOuter + 1.2 * scale, dialRim);

    final n = segments.length;

    // —— 채워진 루틴 조각
    for (var i = 0; i < n; i++) {
      final seg = segments[i];
      final next = segments[(i + 1) % n];
      var startRad = (seg.startMinutesFromMidnight / (24 * 60)) * 2 * math.pi -
          math.pi / 2;
      var endRad = (next.startMinutesFromMidnight / (24 * 60)) * 2 * math.pi -
          math.pi / 2;
      var sweep = endRad - startRad;
      if (sweep <= 0) sweep += 2 * math.pi;

      final isActive = seg.id == activeSegmentId;
      var fillColor = Color.lerp(seg.color, Colors.white, 0.06)!;
      if (isActive) {
        fillColor = Color.lerp(fillColor, Colors.white, 0.12)!;
      }

      final path = Path();
      _addAnnulusSector(path, c, centerHoleR, ringOuter, startRad, sweep);
      canvas.drawPath(
        path,
        Paint()..color = fillColor.withValues(alpha: isActive ? 1.0 : 0.93),
      );
    }

    // —— 정시 사이 작은 점 (0·6·12·18 제외)
    for (var h = 0; h < 24; h++) {
      if (h % 6 == 0) continue;
      final ang = _minutesToRad(h * 60);
      final rDot = (centerHoleR + ringOuter) / 2;
      final p = Offset(
        c.dx + rDot * math.cos(ang),
        c.dy + rDot * math.sin(ang),
      );
      canvas.drawCircle(
        p,
        1.15 * scale,
        Paint()..color = const Color(0xFF8A8790).withValues(alpha: 0.38),
      );
    }

    // —— 루틴 구간 흰색 경계
    for (var i = 0; i < n; i++) {
      final seg = segments[i];
      final prev = segments[(i - 1 + n) % n];
      final startRad =
          (seg.startMinutesFromMidnight / (24 * 60)) * 2 * math.pi -
              math.pi / 2;
      final emphasis = activeSegmentId.isNotEmpty &&
          (seg.id == activeSegmentId || prev.id == activeSegmentId);
      _drawWhiteBoundary(
        canvas,
        c,
        startRad,
        centerHoleR,
        ringOuter,
        scale,
        emphasis: emphasis,
      );
    }

    // —— 바깥 12(자)·6 시 표기 (상=자정 🌙, 하=정오 ☀️)
    _paintCornerHour(canvas, c, ringOuter, scale, -math.pi / 2, '12', '🌙');
    _paintCornerHour(canvas, c, ringOuter, scale, 0, '6', null);
    _paintCornerHour(canvas, c, ringOuter, scale, math.pi / 2, '12', '☀️');
    _paintCornerHour(canvas, c, ringOuter, scale, math.pi, '6', null);

    // —— 현재 시각: 중심에서 바깥까지 흰색 둥근 바늘
    final nowRad = _minutesToRad(nowMinutesFromMidnight);
    final pivotR = 6.2 * scale;
    final handInner = Offset(
      c.dx + pivotR * math.cos(nowRad),
      c.dy + pivotR * math.sin(nowRad),
    );
    final handOuter = Offset(
      c.dx + (ringOuter + 1.5 * scale) * math.cos(nowRad),
      c.dy + (ringOuter + 1.5 * scale) * math.sin(nowRad),
    );
    canvas.drawLine(
      handInner,
      handOuter,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.94)
        ..strokeWidth = 6.8 * scale
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6),
    );
    canvas.drawLine(
      handInner,
      handOuter,
      Paint()
        ..color = Colors.white.withValues(alpha: 1)
        ..strokeWidth = 5.2 * scale
        ..strokeCap = StrokeCap.round,
    );

    // —— 조각 안 라벨 (흰색, 바늘 위에 그려 가독성 유지)
    for (var i = 0; i < n; i++) {
      final seg = segments[i];
      final next = segments[(i + 1) % n];
      var startRad = (seg.startMinutesFromMidnight / (24 * 60)) * 2 * math.pi -
          math.pi / 2;
      var endRad = (next.startMinutesFromMidnight / (24 * 60)) * 2 * math.pi -
          math.pi / 2;
      var sweep = endRad - startRad;
      if (sweep <= 0) sweep += 2 * math.pi;
      final mid = startRad + sweep / 2;
      final rMid = centerHoleR + (ringOuter - centerHoleR) * 0.52;
      _paintSegmentLabel(canvas, c, mid, rMid, seg.label, sweep, scale);
    }

    // —— 중앙 축 (바늘·라벨 위)
    canvas.drawCircle(
      c,
      pivotR + 1.4 * scale,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(c, pivotR, Paint()..color = Colors.white);
    canvas.drawCircle(
      c,
      pivotR,
      Paint()
        ..color = const Color(0xFFD8D4DE).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _PieTimetablePainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.activeSegmentId != activeSegmentId ||
        oldDelegate.nowMinutesFromMidnight != nowMinutesFromMidnight;
  }
}
