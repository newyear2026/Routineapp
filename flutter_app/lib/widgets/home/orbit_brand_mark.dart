import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/home_models.dart';
import '../../theme/routine_palette.dart';
import '../ds/pixel_decoration.dart';
import '../ds/pixel_steps.dart';
import 'circular_timetable_area.dart';

/// 스플래시·온보딩과 같은 원판+새싹 마크.
class OrbitBrandMark extends StatelessWidget {
  const OrbitBrandMark({
    super.key,
    this.size = 240,
    this.showSteps = false,
    this.currentTime = const TimeOfDay(hour: 15, minute: 14),
  });

  final double size;
  final bool showSteps;
  final TimeOfDay currentTime;

  static List<RoutineSegment> sampleSegments(AppLocalizations l10n) => [
        RoutineSegment(
          id: 'wake',
          startMinutesFromMidnight: 7 * 60,
          endMinutesFromMidnight: 8 * 60,
          label: l10n.onboardingDemoWake,
          emoji: '',
          color: RoutinePalette.coral,
        ),
        RoutineSegment(
          id: 'focus',
          startMinutesFromMidnight: 9 * 60,
          endMinutesFromMidnight: 12 * 60,
          label: l10n.onboardingDemoFocus,
          emoji: '',
          color: RoutinePalette.lavender,
        ),
        RoutineSegment(
          id: 'rest',
          startMinutesFromMidnight: 15 * 60,
          endMinutesFromMidnight: 16 * 60,
          label: l10n.catalogBreak,
          emoji: '',
          color: RoutinePalette.blue,
        ),
        RoutineSegment(
          id: 'dinner',
          startMinutesFromMidnight: 18 * 60,
          endMinutesFromMidnight: 19 * 60,
          label: l10n.onboardingDemoDinner,
          emoji: '',
          color: RoutinePalette.amber,
        ),
        RoutineSegment(
          id: 'sleep',
          startMinutesFromMidnight: 23 * 60,
          endMinutesFromMidnight: 24 * 60 - 1,
          label: l10n.catalogSleep,
          emoji: '',
          color: RoutinePalette.violet,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ring = size;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: ring,
          height: ring,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircularTimetableArea(
                routines: sampleSegments(l10n),
                currentTime: currentTime,
                size: ring,
              ),
              Positioned(
                right: ring * 0.08,
                top: ring * 0.02,
                child: const PixelDecoration(asset: 'plant', size: 36),
              ),
            ],
          ),
        ),
        if (showSteps) ...[
          const SizedBox(height: 20),
          const PixelSteps(total: 3, current: 0),
        ],
      ],
    );
  }
}
