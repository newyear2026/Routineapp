import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

import '../../domain/utils/time_minutes.dart';
import '../../models/home_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../orbit_ring_painter.dart';
import 'pixel_orbit_plate.dart';

/// Home 원형 하루 시간표 — Orbit 스타일 리디자인
class CircularTimetableArea extends StatelessWidget {
  const CircularTimetableArea({
    super.key,
    required this.routines,
    required this.currentTime,
    this.activeRoutine,
    this.size = 272,
  });

  final List<RoutineSegment> routines;
  final TimeOfDay currentTime;
  final CurrentRoutine? activeRoutine;
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
    required this.size,
  });

  final List<RoutineSegment> segments;
  final int currentHour;
  final int currentMinute;
  final int nowMinutesFromMidnight;
  final String activeSegmentId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final timeText = TimeMinutes.formatHm(currentHour * 60 + currentMinute);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
              size: Size.square(size), painter: const PixelOrbitPlate()),
          CustomPaint(
            size: Size.square(size),
            // 링은 홈 위젯과 같은 구현을 쓴다 (OrbitRingPainter).
            painter: OrbitRingPainter(
              segments: [
                for (final segment in segments)
                  OrbitRingSegment(
                    id: segment.id,
                    startMinutes: segment.startMinutesFromMidnight,
                    endMinutes: segment.endMinutesFromMidnight,
                    color: segment.color,
                  ),
              ],
              radiusFactor: 0.39,
              activeSegmentId: activeSegmentId,
              nowMinutes: nowMinutesFromMidnight,
            ),
          ),
          CustomPaint(
              size: Size.square(size),
              painter: const PixelOrbitPlate(centerOnly: true)),
          // 중앙은 '시계' 하나만 맡는다. 루틴 이름은 화면 상단 스트립이 이미
          // 말하고 있으므로 여기서 반복하지 않는다 (One Strong Object).
          SizedBox(
            width: size * .44,
            height: size * .44,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeText,
                    style: AppTextStyles.clock.copyWith(
                      fontSize: size >= 280
                          ? 38
                          : size >= 232
                              ? 32
                              : 28,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orbitSurfaceSoft,
                      border: Border.all(color: AppColors.orbitBorder),
                    ),
                    child: Text(
                      AppLocalizations.of(context).commonNow,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
