import 'package:flutter/material.dart';

import 'home_medium_widget_view_model.dart';
import 'mini_circular_timetable.dart';
import 'widget_theme.dart';

/// 홈 화면 Medium 위젯 카드 — 앱 홈의 축소판.
///
/// 정보 위계는 UI_STANDARDS 4를 따른다: 지금 할 루틴 → 상태 → 남은 시간 →
/// 다음 일정. 예전에는 맨 위에 '하루 루틴 시간표' 제목과 '오늘 루틴 진행 중'
/// 부제가 두 줄을 차지했는데, 앞의 것은 위젯 이름이 이미 말하고 뒤의 것은
/// 실제 상태와 무관한 하드코딩이었다. 두 줄을 걷어낸 자리를 본문 글자
/// 크기를 올리는 데 썼다.
class HomeMediumWidget extends StatelessWidget {
  const HomeMediumWidget({
    super.key,
    required this.viewModel,
    this.ringSize = 96,
  });

  final HomeMediumWidgetViewModel viewModel;
  final double ringSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minHeight: 152, maxHeight: 176),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: WidgetTheme.background,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(child: _LeftColumn(vm: viewModel)),
            const SizedBox(width: 10),
            MiniCircularTimetable(
              segments: viewModel.ringSegments,
              currentTime: viewModel.currentTime,
              activeSegmentId: viewModel.activeSegmentId,
              pointerAngleRad: viewModel.pointerAngleRad,
              centerLabel: viewModel.centerTimeLabel,
              size: ringSize,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftColumn extends StatelessWidget {
  const _LeftColumn({required this.vm});

  final HomeMediumWidgetViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 루틴이 없는 날에는 상태도 없다. 빈 배지나 '—'를 남기지 않는다.
        //
        // 시작·종료 시각은 싣지 않는다. 실제 위젯 폭에서 왼쪽 칸은 130dp 안팎이라
        // 배지와 '10:00 – 12:00'을 한 줄에 놓으면 시간이 잘린다. 아래
        // 타이밍 힌트('종료까지 1시간 56분 남음')가 같은 것을 더 쓸모 있게
        // 말하므로 범위 쪽을 뺐다. 정확한 시각은 앱에서 본다.
        if (vm.currentRoutineStatusLabel.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: _StatusBadge(label: vm.currentRoutineStatusLabel),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          vm.currentRoutineTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: WidgetTheme.titleSize,
            fontWeight: FontWeight.w800,
            color: WidgetTheme.textPrimary,
            height: 1.15,
          ),
        ),
        if (vm.currentRoutineTimingHint.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            vm.currentRoutineTimingHint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: WidgetTheme.bodySize,
              fontWeight: FontWeight.w600,
              color: WidgetTheme.textMuted,
            ),
          ),
        ],
        const SizedBox(height: 10),
        _NextRoutineChip(
          title: vm.nextRoutineTitle,
          time: vm.nextRoutineTime,
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          // 흰 글자와 5.66:1. 예전 테라코타(#E07A5F)는 2.95:1이었다.
          color: WidgetTheme.accent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: WidgetTheme.captionSize,
            fontWeight: FontWeight.w700,
            color: WidgetTheme.onAccent,
          ),
        ),
      );
}

class _NextRoutineChip extends StatelessWidget {
  const _NextRoutineChip({required this.title, required this.time});

  final String title;
  final String time;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: WidgetTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WidgetTheme.border),
        ),
        child: Row(
          children: [
            const Text(
              '다음',
              style: TextStyle(
                fontSize: WidgetTheme.captionSize,
                fontWeight: FontWeight.w700,
                color: WidgetTheme.textMuted,
              ),
            ),
            const SizedBox(width: 8),
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
        ),
      );
}
