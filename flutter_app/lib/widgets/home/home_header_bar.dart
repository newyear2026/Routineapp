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
              _CircleIconButton(
                icon: Icons.insights_rounded,
                tooltip: '오늘 진행',
                color: HomeTheme.accentPink,
                background: HomeTheme.accentPink.withValues(alpha: 0.22),
                onTap: onProgressTap,
              ),
              const SizedBox(width: 8),
              _CircleIconButton(
                icon: Icons.settings_rounded,
                tooltip: '설정',
                color: const Color(0xFFD4C5F0),
                background: const Color(0xFFD4C5F0).withValues(alpha: 0.22),
                onTap: onSettingsTap,
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

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.background,
    this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}
