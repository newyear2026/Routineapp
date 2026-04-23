import 'package:flutter/material.dart';

import '../../models/home_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class HomeDailySummarySection extends StatelessWidget {
  const HomeDailySummarySection({
    super.key,
    required this.progress,
    required this.isUpcoming,
    required this.isEmptyDay,
    this.statusLabel,
    this.nextRoutine,
  });

  final HomeProgress progress;
  final String? statusLabel;
  final NextRoutine? nextRoutine;
  final bool isUpcoming;
  final bool isEmptyDay;

  @override
  Widget build(BuildContext context) {
    final completionRate = progress.total > 0
        ? ((progress.completed / progress.total) * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.orbitBorder.withValues(alpha: 0.92),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DAY SNAPSHOT',
            style: AppTextStyles.captionTight.copyWith(
              color: AppColors.textMuted.withValues(alpha: 0.78),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEmptyDay ? '차분한 빈 화면으로 유지했어요' : '캐릭터 없이도 흐름이 보이도록 정리했어요',
            style: AppTextStyles.titleSection.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(
            isEmptyDay
                ? '새 루틴을 추가하면 이 영역이 오늘의 진행과 다음 전환 정보를 담습니다.'
                : '진행률, 현재 상태, 다음 전환 시점을 작게 모아두었습니다.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  icon: Icons.done_all_rounded,
                  label: '완료율',
                  value: progress.total > 0 ? '$completionRate%' : '-',
                  helper: progress.total > 0
                      ? '${progress.completed}/${progress.total} 루틴'
                      : '오늘 루틴 없음',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  icon: Icons.tune_rounded,
                  label: '현재 상태',
                  value: isUpcoming ? '대기 중' : '진행 흐름',
                  helper: statusLabel ?? '지금 루틴 상태가 여기에 반영됩니다',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  icon: Icons.north_east_rounded,
                  label: '다음 전환',
                  value: nextRoutine?.time ?? '-',
                  helper: nextRoutine?.name ?? '다음 루틴 없음',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
  });

  final IconData icon;
  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.94),
            AppColors.orbitSurface.withValues(alpha: 0.86),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.orbitBorder.withValues(alpha: 0.94),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.orbitPrimary),
          const SizedBox(height: 14),
          Text(
            label,
            style: AppTextStyles.captionTight.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyStrong.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}
