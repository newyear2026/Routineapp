import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/utils/time_minutes.dart';
import '../theme/app_colors.dart';
import '../widgets/ds/pixel_digits.dart';
import '../widgets/home/pixel_orbit_plate.dart';
import '../widgets/orbit_ring_painter.dart';
import 'medium_ring_segment.dart';
import 'widget_theme.dart';

/// Medium 위젯의 24시간 원형 시간표.
///
/// 홈 화면과 **같은 [OrbitRingPainter]**를 쓴다. 예전에는 위젯만 두꺼운
/// 동심원 도넛으로 그려서, 같은 하루를 앱과 위젯이 다른 모양으로 보여줬다.
///
/// 작은 위젯에서도 00·06·12·18 라벨과 현재 시각이 읽히도록
/// 픽셀 원판의 계단과 시계 글자 크기를 별도로 조정한다.
class MiniCircularTimetable extends StatelessWidget {
  const MiniCircularTimetable({
    super.key,
    required this.segments,
    required this.currentTime,
    this.activeSegmentId,
    this.pointerAngleRad,
    required this.centerLabel,
    this.size = 120,
    this.rabbitPalette = false,
    this.stargazerPalette = false,
  });

  final List<MediumRingSegment> segments;
  final TimeOfDay currentTime;
  final String? activeSegmentId;

  /// 페이로드가 각도를 직접 넘길 때 사용. null이면 [currentTime]으로 계산한다.
  final double? pointerAngleRad;
  final String centerLabel;
  final double size;
  final bool rabbitPalette;
  final bool stargazerPalette;

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
            painter: PixelOrbitPlate(
              step: size / 54,
              dialColor: rabbitPalette
                  ? const Color(0xFFFFE3D0)
                  : stargazerPalette
                      ? const Color(0xFF0A3446)
                      : AppColors.dialSurface,
              surfaceColor: rabbitPalette
                  ? const Color(0xFFFFFCF3)
                  : AppColors.orbitSurface,
            ),
          ),
          CustomPaint(
            size: Size.square(size),
            painter: OrbitRingPainter(
              devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
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
              trackColor: rabbitPalette
                  ? const Color(0xFFC5E4CA)
                  : stargazerPalette
                      ? const Color(0xFF1D6A7C)
                      : AppColors.orbitHalo,
              pointerColor: rabbitPalette
                  ? const Color(0xFFDB665E)
                  : stargazerPalette
                      ? const Color(0xFFF4C430)
                      : AppColors.orbitPrimary,
              hourLabelColor: stargazerPalette
                  ? const Color(0xFFE0F2F0)
                  : AppColors.textStrong,
              tickColor: stargazerPalette
                  ? const Color(0xFFBCE4E8)
                  : AppColors.textMuted,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PixelDigits(
                timeText,
                height: size * 0.15,
                maxWidth: size * 0.5,
                color: WidgetTheme.textPrimary,
              ),
              SizedBox(height: size * 0.03),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: rabbitPalette
                      ? const Color(0xFFFFE9D8)
                      : stargazerPalette
                          ? const Color(0xFFFFE295)
                          : AppColors.orbitSurfaceSoft,
                  border: Border.all(color: AppColors.orbitBorder),
                ),
                child: Text(
                  centerLabel,
                  style: TextStyle(
                    fontSize: math.max(9, size * 0.083),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: WidgetTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
