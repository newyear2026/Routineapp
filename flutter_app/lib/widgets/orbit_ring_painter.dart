import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 24시간 링에 그릴 한 구간.
///
/// 화면(`RoutineSegment`)과 위젯(`MediumRingSegment`)이 서로 다른 모델을 쓰므로
/// 링이 아는 최소 정보만 받는다.
@immutable
class OrbitRingSegment {
  const OrbitRingSegment({
    required this.id,
    required this.startMinutes,
    required this.endMinutes,
    required this.color,
  });

  final String id;
  final int startMinutes;
  final int endMinutes;
  final Color color;

  int get sweepMinutes => endMinutes - startMinutes;

  @override
  bool operator ==(Object other) =>
      other is OrbitRingSegment &&
      other.id == id &&
      other.startMinutes == startMinutes &&
      other.endMinutes == endMinutes &&
      other.color.toARGB32() == color.toARGB32();

  @override
  int get hashCode => Object.hash(id, startMinutes, endMinutes, color);
}

/// 하루 24시간 원형 링 — **홈 화면과 홈 위젯이 함께 쓰는 단 하나의 구현**.
///
/// 예전에는 홈은 얇은 호 + 24틱, 위젯은 두꺼운 도넛으로 서로 다른 물건을
/// 그렸다. 같은 데이터를 다른 시각 언어로 보여주면 위젯이 앱의 축소판으로
/// 읽히지 않는다.
///
/// 좌표계: 0시 = 12시 방향(위), 시계 방향 증가.
/// 치수는 [referenceSize] 기준으로 비례 축소되므로 286(홈)과 120(위젯)이
/// 같은 비율을 유지한다.
class OrbitRingPainter extends CustomPainter {
  OrbitRingPainter({
    required this.segments,
    required this.nowMinutes,
    this.activeSegmentId = '',
    this.showHourLabels = true,
    this.showNowPointer = true,
    this.radiusFactor = 0.34,
  });

  final List<OrbitRingSegment> segments;
  final int nowMinutes;
  final String activeSegmentId;

  /// 작은 크기에서는 00·06·12·18 라벨이 4px 남짓으로 줄어 읽히지 않는다.
  /// 위젯처럼 라벨을 끄는 쪽은 그만큼 링을 키운다([radiusFactor]).
  final bool showHourLabels;

  /// 루틴 편집 미리보기처럼 '지금'이 뜻이 없는 곳에서는 바늘을 끈다.
  final bool showNowPointer;

  /// 링 반지름 / 박스 폭. 라벨을 그리려면 바깥 여백이 필요하다.
  final double radiusFactor;

  static const double referenceSize = 292;

  double _minutesToRad(int minutes) =>
      (minutes / (24 * 60)) * 2 * math.pi - math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / referenceSize;
    final orbitRadius = size.width * radiusFactor;
    final segmentStroke = 11 * scale;
    final trackStroke = 9 * scale;
    const gapRad = 0.04;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: orbitRadius),
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..color = AppColors.orbitHalo
        ..style = PaintingStyle.stroke
        ..strokeWidth = trackStroke
        ..strokeCap = StrokeCap.round,
    );

    _paintHourTicks(canvas, center, orbitRadius, trackStroke, scale);

    for (final segment in segments) {
      final sweep = (segment.sweepMinutes / (24 * 60)) * 2 * math.pi;
      if (sweep <= 0) continue;

      final start = _minutesToRad(segment.startMinutes) + gapRad;
      final safeSweep = math.max(0.02, sweep - gapRad * 2);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: orbitRadius),
        start,
        safeSweep,
        false,
        Paint()
          ..color = segment.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = segmentStroke
          ..strokeCap = StrokeCap.round,
      );
    }

    if (showHourLabels) {
      const labels = <(String, double)>[
        ('00', -math.pi / 2),
        ('06', 0),
        ('12', math.pi / 2),
        ('18', math.pi),
      ];
      for (final (text, angle) in labels) {
        _paintHourLabel(
          canvas,
          center,
          orbitRadius + 34 * scale,
          angle,
          text,
          scale,
        );
      }
    }

    if (showNowPointer) {
      _paintNowPointer(canvas, center, orbitRadius, scale);
    }
  }

  void _paintHourTicks(
    Canvas canvas,
    Offset center,
    double orbitRadius,
    double trackStroke,
    double scale,
  ) {
    for (var hour = 0; hour < 24; hour++) {
      final angle = _minutesToRad(hour * 60);
      final isMajor = hour % 6 == 0;
      final tickLength = isMajor ? 11 * scale : 6 * scale;
      final base = orbitRadius - trackStroke / 2 - 10 * scale;
      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * base,
          center.dy + math.sin(angle) * base,
        ),
        Offset(
          center.dx + math.cos(angle) * (base - tickLength),
          center.dy + math.sin(angle) * (base - tickLength),
        ),
        Paint()
          ..color = AppColors.textMuted.withValues(alpha: isMajor ? 0.34 : 0.18)
          ..strokeWidth = isMajor ? 2.4 * scale : 1.3 * scale
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintHourLabel(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    String text,
    double scale,
  ) {
    final position = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
    final painter = TextPainter(
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
    )..layout(maxWidth: 56 * scale);
    painter.paint(
      canvas,
      Offset(
        position.dx - painter.width / 2,
        position.dy - painter.height / 2,
      ),
    );
  }

  void _paintNowPointer(
    Canvas canvas,
    Offset center,
    double orbitRadius,
    double scale,
  ) {
    final nowRad = _minutesToRad(nowMinutes);
    final nowCenter = Offset(
      center.dx + math.cos(nowRad) * (orbitRadius + 4 * scale),
      center.dy + math.sin(nowRad) * (orbitRadius + 4 * scale),
    );

    canvas.drawLine(
      center,
      nowCenter,
      Paint()
        ..color = AppColors.orbitPrimary.withValues(alpha: 0.5)
        ..strokeWidth = 1.5 * scale,
    );
    canvas.drawCircle(
      nowCenter,
      7 * scale,
      Paint()..color = AppColors.orbitSurface,
    );
    canvas.drawCircle(
      nowCenter,
      4.5 * scale,
      Paint()..color = AppColors.orbitPrimary,
    );
  }

  @override
  bool shouldRepaint(covariant OrbitRingPainter oldDelegate) {
    return oldDelegate.nowMinutes != nowMinutes ||
        oldDelegate.activeSegmentId != activeSegmentId ||
        oldDelegate.showHourLabels != showHourLabels ||
        oldDelegate.showNowPointer != showNowPointer ||
        oldDelegate.radiusFactor != radiusFactor ||
        !listEquals(oldDelegate.segments, segments);
  }
}
