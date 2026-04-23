import 'package:flutter/material.dart';

import '../../application/mappers/home_view_mapper.dart';
import '../../domain/models/routine.dart';
import '../../domain/utils/time_minutes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../ds/app_button.dart';

class HomeRoutineManagerSection extends StatelessWidget {
  const HomeRoutineManagerSection({
    super.key,
    required this.routines,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Routine> routines;
  final VoidCallback onAdd;
  final ValueChanged<Routine> onEdit;
  final ValueChanged<Routine> onDelete;

  @override
  Widget build(BuildContext context) {
    final sorted = List<Routine>.from(routines)
      ..sort((a, b) {
        final time = a.startMinutesFromMidnight.compareTo(
          b.startMinutesFromMidnight,
        );
        if (time != 0) return time;
        return a.title.compareTo(b.title);
      });

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.orbitBorder.withValues(alpha: 0.92),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ROUTINE MANAGER',
                      style: AppTextStyles.captionTight.copyWith(
                        color: AppColors.textMuted.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '루틴 추가, 수정, 삭제',
                      style: AppTextStyles.titleSection.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '여기서 바꾸면 홈 카드와 원형 시간표에 바로 반영됩니다.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted.withValues(alpha: 0.86),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: '새 루틴',
                icon: Icons.add_rounded,
                onPressed: onAdd,
                expand: false,
                height: 44,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (sorted.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.orbitBorder.withValues(alpha: 0.8),
                ),
              ),
              child: Text(
                '등록된 루틴이 아직 없어요. 새 루틴을 추가하면 원형 시간표가 바로 채워집니다.',
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  color: AppColors.textMuted.withValues(alpha: 0.92),
                ),
              ),
            )
          else
            ...sorted.map(
              (routine) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RoutineManagerTile(
                  routine: routine,
                  onTap: () => onEdit(routine),
                  onDelete: () => onDelete(routine),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoutineManagerTile extends StatelessWidget {
  const _RoutineManagerTile({
    required this.routine,
    required this.onTap,
    required this.onDelete,
  });

  final Routine routine;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final repeat = HomeViewMapper.weekdayLabels(routine.repeatWeekdays).join(', ');
    final timeLabel =
        '${TimeMinutes.formatHm(routine.startMinutesFromMidnight)} - ${TimeMinutes.formatHm(routine.endMinutesFromMidnight)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: routine.color.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: routine.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(routine.iconEmoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      repeat,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted.withValues(alpha: 0.86),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: '루틴 수정',
                onPressed: onTap,
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.textPrimary.withValues(alpha: 0.84),
              ),
              IconButton(
                tooltip: '루틴 삭제',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.warning.withValues(alpha: 0.92),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
