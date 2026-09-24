import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/utils/time_minutes.dart';
import '../widgets/home/pixel_orbit_plate.dart';
import '../widgets/orbit_ring_painter.dart';
import 'medium_ring_segment.dart';
import 'widget_theme.dart';

/// Medium 위젯의 24시간 원형 시간표.
///
/// 홈 화면과 **같은 [OrbitRingPainter]**를 쓴다. 예전에는 위젯만 두꺼운
/// 동심원 도넛으로 그려서, 같은 하루를 앱과 위젯이 다른 모양으로 보여줬다.
///
/// 위젯 크기(120 안팎)에서는 00·06·12·18 라벨이 4px 남짓으로 줄어 읽히지
/// 않으므로 라벨을 끄고, 그만큼 링을 키운다. 현재 시각은 중앙 숫자가 말한다.
class MiniCircularTimetable extends StatelessWidget {
  const MiniCircularTimetable({
    super.key,
    required this.segments,
    required this.currentTime,
    this.activeSegmentId,
    this.pointerAngleRad,
    required this.centerLabel,
    this.size = 120,
  });

  final List<MediumRingSegment> segments;
  final TimeOfDay currentTime;
  final String? activeSegmentId;

  /// 페이로드가 각도를 직접 넘길 때 사용. null이면 [currentTime]으로 계산한다.
  final double? pointerAngleRad;
  final String centerLabel;
  final double size;

  static double pointerAngleFromTime(TimeOfDay t) {
    final m = t.hour * 60 + t.minute;
    return (m / (24 * 60)) * 2 * math.pi - math.pi / 2;
  }

  /// 페이로드의 각도를 다시 '자정 기준 분'으로 되돌린다.
  static int _minutesFromAngle(double angleRad) {
    final normalized = (angleRad + math.pi / 2) % (2 * math.pi);
    return ((normalized / (2 * math.pi)) * 24 * 60).round() % (24 * 60);
  }

  @override
  Widget build(BuildContext context) {
    final nowMinutes = pointerAngleRad != null
        ? _minutesFromAngle(pointerAngleRad!)
        : currentTime.hour * 60 + currentTime.minute;
    final timeText = TimeMinutes.formatTimeOfDay(currentTime);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 홈과 같은 계단 원판을 쓴다. 매끈한 흰 원은 이 앱에서 여기에만
          // 남아 있던 모양이었다. 칸 크기는 size/146이 1px 아래로 내려가므로
          // 직접 준다.
          CustomPaint(
            size: Size.square(size),
            painter: PixelOrbitPlate(step: size / 54),
          ),
          CustomPaint(
            size: Size.square(size),
            painter: OrbitRingPainter(
              segments: [
                for (final segment in segments)
                  OrbitRingSegment(
                    id: segment.id,
                    startMinutes: segment.startMinutesFromMidnight,
                    endMinutes:
                        segment.startMinutesFromMidnight + segment.sweepMinutes,
                    color: segment.color,
                  ),
              ],
              activeSegmentId: activeSegmentId ?? '',
              nowMinutes: nowMinutes,
              showHourLabels: true,
              radiusFactor: 0.39,
              // 292는 홈(286) 기준이라 이 크기에서는 눈금·라벨이 사라진다.
              referenceSize: 150,
              // 기본 상한(0.448)은 홈 글자 크기에서 정한 값이라, 여기서는
              // 라벨이 계단 원판(0.48) 테두리를 넘어 잘린다.
              hourLabelRadiusFactor: 0.425,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeText,
                style: TextStyle(
                  fontSize: size * 0.19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1,
                  color: WidgetTheme.textPrimary,
                ),
              ),
              SizedBox(height: size * 0.03),
              Text(
                centerLabel,
                style: TextStyle(
                  fontSize: math.max(9, size * 0.083),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: WidgetTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
