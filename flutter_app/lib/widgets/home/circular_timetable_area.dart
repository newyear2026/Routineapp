import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

import '../../domain/utils/time_minutes.dart';
import '../../models/home_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_pixel_style.dart';
import '../ds/pixel_digits.dart';
import '../ds/routine_mark.dart';
import '../orbit_ring_painter.dart';
import 'pixel_orbit_plate.dart';
import 'routine_ring_icon_layout.dart';
import '../store/character_pack_scope.dart';

/// Home 원형 하루 시간표 — Orbit 스타일 리디자인
class CircularTimetableArea extends StatelessWidget {
  const CircularTimetableArea({
    super.key,
    required this.routines,
    required this.currentTime,
    this.activeRoutine,
    this.showNowLabel = true,
    this.size = 272,
  });

  final List<RoutineSegment> routines;
  final TimeOfDay currentTime;
  final CurrentRoutine? activeRoutine;
  final bool showNowLabel;
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
      showNowLabel: showNowLabel,
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
    required this.showNowLabel,
    required this.size,
  });

  final List<RoutineSegment> segments;
  final int currentHour;
  final int currentMinute;
  final int nowMinutesFromMidnight;
  final String activeSegmentId;
  final bool showNowLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final timeText = TimeMinutes.formatHm(currentHour * 60 + currentMinute);
    final nowLabel = AppLocalizations.of(context).commonNow;
    final iconPlacements = RoutineRingIconLayout.arrange(
      segments: segments,
      dialSize: size,
      activeSegmentId: activeSegmentId,
    );
    final palette = CharacterPackScope.skinOf(context).appDial;
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: PixelOrbitPlate(
              dialColor: palette.dial ?? AppColors.dialSurface,
              surfaceColor: surface,
            ),
          ),
          CustomPaint(
            size: Size.square(size),
            // 링은 홈 위젯과 같은 구현을 쓴다 (OrbitRingPainter).
            painter: OrbitRingPainter(
              devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
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
              trackColor: palette.track ?? AppColors.orbitHalo,
              pointerColor: primary,
            ),
          ),
          CustomPaint(
            size: Size.square(size),
            painter: PixelOrbitPlate(centerOnly: true, surfaceColor: surface),
          ),
          for (final placement in iconPlacements)
            Positioned(
              left: placement.bounds.left,
              top: placement.bounds.top,
              child: _RoutineRingIconBadge(
                placement: placement,
                active: placement.segment.id == activeSegmentId,
              ),
            ),
          // 중앙은 '시계' 하나만 맡는다. 루틴 이름은 화면 상단 스트립이 이미
          // 말하고 있으므로 여기서 반복하지 않는다 (One Strong Object).
          SizedBox(
            width: size * .44,
            height: size * .44,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Semantics(
                label: '$nowLabel $timeText',
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PixelDigits(
                        timeText,
                        key: const Key('home-ring-current-time'),
                        height: size >= 280
                            ? 30
                            : size >= 232
                                ? 26
                                : 22,
                        maxWidth: size * .44 * .86,
                      ),
                      if (showNowLabel) ...[
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
                            nowLabel,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineRingIconBadge extends StatelessWidget {
  const _RoutineRingIconBadge({
    required this.placement,
    required this.active,
  });

  final RoutineRingIconPlacement placement;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final segment = placement.segment;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Container(
          key: Key('home-ring-icon-${segment.id}'),
          width: placement.size,
          height: placement.size,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: AppColors.orbitSurface,
            shape: AppPixelStyle.shape(
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : AppColors.textPrimary,
              width: active ? 2 : 1.2,
              step: 2,
              steps: 2,
            ),
          ),
          child: RoutineMark(
            icon: segment.iconId!,
            color: segment.color,
            size: placement.size * 0.78,
          ),
        ),
      ),
    );
  }
}
