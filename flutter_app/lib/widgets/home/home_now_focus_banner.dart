import 'package:flutter/material.dart';
import '../../models/home_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// 홈 최상단 — 캐릭터 없이 현재 집중 블록을 선명하게 보여주는 카드
class HomeNowFocusBanner extends StatelessWidget {
  const HomeNowFocusBanner({
    super.key,
    required this.routineName,
    required this.timingHint,
    required this.progress,
    this.nextRoutine,
    this.compact = false,
    this.isUpcoming = false,
  });

  final String routineName;
  final String timingHint;
  final HomeProgress progress;
  final NextRoutine? nextRoutine;
  final bool compact;
  final bool isUpcoming;

  @override
  Widget build(BuildContext context) {
    final statusLabel = isUpcoming ? 'UP NEXT' : 'IN FOCUS';
    final title = isUpcoming ? '곧 시작할 블록' : '지금 집중할 블록';
    final progressLabel = progress.total > 0
        ? '${progress.completed}/${progress.total} 완료'
        : '루틴 준비';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 18,
        vertical: compact ? 14 : 16,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.96),
            AppColors.orbitHalo.withValues(alpha: 0.22),
            AppColors.orbitSurfaceSoft.withValues(alpha: 0.72),
          ],
        ),
        border: Border.all(
          color: AppColors.orbitPrimary.withValues(alpha: 0.16),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.orbitPrimary.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.orbitPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: AppTextStyles.captionTight.copyWith(
                    color: AppColors.orbitPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: compact ? 42 : 46,
                height: compact ? 42 : 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: AppColors.orbitPrimaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orbitPrimary.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  isUpcoming ? Icons.upcoming_rounded : Icons.bolt_rounded,
                  color: Colors.white,
                  size: compact ? 22 : 24,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 14 : 16),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            routineName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.hero.copyWith(
              fontSize: compact ? 24 : 28,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            timingHint,
            style: AppTextStyles.body.copyWith(
              fontSize: compact ? 14 : 15,
              color: AppColors.textMuted.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.track_changes_rounded,
                label: progressLabel,
              ),
              _InfoChip(
                icon: Icons.schedule_rounded,
                label: nextRoutine != null
                    ? '다음 ${nextRoutine!.time}'
                    : '오늘 마지막 블록',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.orbitBorder.withValues(alpha: 0.9),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.captionTight.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
