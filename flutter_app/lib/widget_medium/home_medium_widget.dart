import 'package:flutter/material.dart';

import 'home_medium_widget_view_model.dart';
import 'mini_circular_timetable.dart';

/// iOS Medium 스타일(가로형) **하루 루틴 시간표** 위젯 카드.
///
/// - 캐릭터/얼굴 헤더 없음, 텍스트 헤더만
/// - [HomeMediumWidgetViewModel] 주입 — 하드코딩 대신 selector 사용
class HomeMediumWidget extends StatelessWidget {
  const HomeMediumWidget({
    super.key,
    required this.viewModel,
    this.ringSize = 152,
  });

  final HomeMediumWidgetViewModel viewModel;
  final double ringSize;

  static const _ivory = Color(0xFFFFF7ED);
  static const _brown = Color(0xFF5C4033);
  static const _muted = Color(0xFF8B7D72);
  static const _badge = Color(0xFFE07A5F);

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minHeight: 152, maxHeight: 176),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _ivory,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 12,
              child: _LeftColumn(
                  vm: vm, badgeColor: _badge, brown: _brown, muted: _muted),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 11,
              child: Align(
                alignment: Alignment.centerRight,
                child: MiniCircularTimetable(
                  segments: vm.ringSegments,
                  currentTime: vm.currentTime,
                  activeSegmentId: vm.activeSegmentId,
                  pointerAngleRad: vm.pointerAngleRad,
                  centerLabel: vm.centerTimeLabel,
                  size: ringSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftColumn extends StatelessWidget {
  const _LeftColumn({
    required this.vm,
    required this.badgeColor,
    required this.brown,
    required this.muted,
  });

  final HomeMediumWidgetViewModel vm;
  final Color badgeColor;
  final Color brown;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          vm.headerTitle,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: brown,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          vm.subtitle,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: muted.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vm.currentRoutineIconEmoji,
              style: const TextStyle(fontSize: 22, height: 1.1),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                vm.currentRoutineTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: brown,
                  height: 1.12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                vm.currentRoutineTimeRange,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: brown.withValues(alpha: 0.92),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                vm.currentRoutineStatusLabel,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Icon(Icons.search_rounded,
                size: 15, color: muted.withValues(alpha: 0.9)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                vm.nextRoutineLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
