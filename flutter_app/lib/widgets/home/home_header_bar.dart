import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 12),
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
                      style: const TextStyle(
                        fontSize: 13,
                        color: HomeTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$greeting 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: HomeTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _CircleIconButton(
                icon: Icons.trending_up,
                color: HomeTheme.accentPink,
                background: HomeTheme.accentPink.withValues(alpha: 0.2),
                onTap: onProgressTap,
              ),
              const SizedBox(width: 8),
              _CircleIconButton(
                icon: Icons.settings,
                color: const Color(0xFFD4C5F0),
                background: const Color(0xFFD4C5F0).withValues(alpha: 0.2),
                onTap: onSettingsTap,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '오늘의 진행',
                style: TextStyle(fontSize: 12, color: HomeTheme.textMuted),
              ),
              Text(
                '${progress.completed}/${progress.total}',
                style: const TextStyle(fontSize: 12, color: HomeTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: HomeTheme.textMuted.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(HomeTheme.accentPink),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.background,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
