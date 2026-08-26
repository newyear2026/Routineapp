import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

import '../../domain/utils/time_minutes.dart';
import '../../models/home_models.dart';
import '../../theme/app_colors.dart';
import '../orbit_ring_painter.dart';

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
              activeSegmentId: activeSegmentId,
              nowMinutes: nowMinutesFromMidnight,
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
          // 중앙은 '시계' 하나만 맡는다. 루틴 이름은 화면 상단 스트립이 이미
          // 말하고 있으므로 여기서 반복하지 않는다 (One Strong Object).
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
                    color: AppColors.orbitSurfaceSoft,
                    borderRadius: BorderRadius.circular(999),
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
        ],
      ),
    );
  }
}

