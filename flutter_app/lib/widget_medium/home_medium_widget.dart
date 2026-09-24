import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

import '../theme/app_pixel_style.dart';
import '../widgets/ds/pixel_decoration.dart';
import '../widgets/ds/pixel_icon.dart';
import '../widgets/ds/routine_mark.dart';
import 'home_medium_widget_view_model.dart';
import 'mini_circular_timetable.dart';
import 'widget_theme.dart';

/// 홈 화면 Medium 위젯 카드 — 앱 홈의 축소판.
class HomeMediumWidget extends StatelessWidget {
  const HomeMediumWidget({
    super.key,
    required this.viewModel,
    this.ringSize = 108,
  });

  final HomeMediumWidgetViewModel viewModel;
  final double ringSize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minHeight: 152, maxHeight: 176),
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: ShapeDecoration(
          color: WidgetTheme.background,
          shape: AppPixelStyle.shape(),
        ),
        child: Row(
          children: [
            MiniCircularTimetable(
              segments: viewModel.ringSegments,
              currentTime: viewModel.currentTime,
              activeSegmentId: viewModel.activeSegmentId,
              pointerAngleRad: viewModel.pointerAngleRad,
              centerLabel: viewModel.centerTimeLabel,
              size: ringSize,
            ),
            const SizedBox(width: 12),
            Container(width: 1, color: WidgetTheme.border),
            const SizedBox(width: 12),
            Expanded(child: _RightColumn(vm: viewModel, l10n: l10n)),
          ],
        ),
      ),
    );
  }
}

class _RightColumn extends StatelessWidget {
  const _RightColumn({required this.vm, required this.l10n});

  final HomeMediumWidgetViewModel vm;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: WidgetTheme.bodySize,
                  fontWeight: FontWeight.w800,
                  color: WidgetTheme.textPrimary,
                ),
              ),
            ),
            const PixelDecoration(asset: 'plant', size: 22),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            RoutineMark(
              icon: vm.currentRoutineIconId,
              color: vm.currentRoutineColor,
              size: 32,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vm.currentRoutineTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: WidgetTheme.titleSize,
                      fontWeight: FontWeight.w800,
                      color: WidgetTheme.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  if (vm.currentRoutineTimeRange.isNotEmpty)
                    Text(
                      vm.currentRoutineTimeRange,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: WidgetTheme.captionSize,
                        fontWeight: FontWeight.w600,
                        color: WidgetTheme.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _NextRoutineChip(
          title: vm.nextRoutineTitle,
          time: vm.nextRoutineTime,
          nextLabel: l10n.commonNext,
        ),
      ],
    );
  }
}

class _NextRoutineChip extends StatelessWidget {
  const _NextRoutineChip({
    required this.title,
    required this.time,
    required this.nextLabel,
  });

  final String title;
  final String time;
  final String nextLabel;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const PixelIcon(
            PixelGlyph.progress,
            size: 16,
            color: WidgetTheme.textMuted,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 40),
            child: Text(
              nextLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: WidgetTheme.captionSize,
                fontWeight: FontWeight.w700,
                color: WidgetTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: WidgetTheme.bodySize,
                fontWeight: FontWeight.w700,
                color: WidgetTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            time,
            style: const TextStyle(
              fontSize: WidgetTheme.captionSize,
              fontWeight: FontWeight.w600,
              color: WidgetTheme.textMuted,
            ),
          ),
        ],
      );
}
