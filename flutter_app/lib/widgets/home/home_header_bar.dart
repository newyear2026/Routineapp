import 'package:flutter/material.dart';
import '../ds/app_icon_button.dart';
import '../../models/home_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class HomeHeaderBar extends StatelessWidget {
  const HomeHeaderBar({
    super.key,
    required this.dateString,
    required this.dayOfWeekLabel,
    required this.greeting,
    required this.progress,
    this.onProgressTap,
    this.onSettingsTap,
  });

  final String dateString;
  final String dayOfWeekLabel;
  final String greeting;
  final HomeProgress progress;
  final VoidCallback? onProgressTap;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final pct = progress.total > 0 ? progress.completed / progress.total : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$dateString $dayOfWeekLabel',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted.withValues(alpha: 0.88),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '오늘의 궤도',
                      style: AppTextStyles.hero.copyWith(
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$greeting. 지금 흐름을 바로 확인하세요.',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted.withValues(alpha: 0.84),
                      ),
                    ),
                  ],
                ),
              ),
              AppIconButton(
                icon: Icons.insights_rounded,
                tooltip: '오늘 진행',
                foregroundColor: AppColors.orbitPrimary,
                backgroundColor: AppColors.orbitHalo.withValues(alpha: 0.32),
                onPressed: onProgressTap,
              ),
              const SizedBox(width: 8),
              AppIconButton(
                icon: Icons.settings_rounded,
                tooltip: '설정',
                foregroundColor: AppColors.textStrong,
                backgroundColor:
                    AppColors.orbitSurfaceSoft.withValues(alpha: 0.7),
                onPressed: onSettingsTap,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '오늘의 진행',
                style: AppTextStyles.captionTight.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted.withValues(alpha: 0.74),
                ),
              ),
              Text(
                '${progress.completed}/${progress.total}',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.orbitBorder.withValues(alpha: 0.32),
              valueColor: AlwaysStoppedAnimation(
                AppColors.orbitPrimary.withValues(alpha: 0.72),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
