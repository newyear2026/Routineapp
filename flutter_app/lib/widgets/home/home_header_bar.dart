import 'package:flutter/material.dart';
import '../ds/app_icon_button.dart';
import '../../models/home_models.dart';
import '../../theme/home_theme.dart';

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
      padding: const EdgeInsets.fromLTRB(24, 44, 24, 8),
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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: HomeTheme.textMuted.withValues(alpha: 0.95),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$greeting 👋',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.3,
                        color: HomeTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              AppIconButton(
                icon: Icons.insights_rounded,
                tooltip: '오늘 진행',
                foregroundColor: HomeTheme.accentPink,
                backgroundColor: HomeTheme.accentPink.withValues(alpha: 0.22),
                onPressed: onProgressTap,
              ),
              const SizedBox(width: 8),
              AppIconButton(
                icon: Icons.settings_rounded,
                tooltip: '설정',
                foregroundColor: const Color(0xFFD4C5F0),
                backgroundColor:
                    const Color(0xFFD4C5F0).withValues(alpha: 0.22),
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
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: HomeTheme.textMuted.withValues(alpha: 0.75),
                ),
              ),
              Text(
                '${progress.completed}/${progress.total}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: HomeTheme.textMuted.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: HomeTheme.textMuted.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(
                HomeTheme.accentPink.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
