import 'package:flutter/material.dart';
import '../../models/progress_models.dart';
import '../../theme/home_theme.dart';

class ProgressMiniStatsRow extends StatelessWidget {
  const ProgressMiniStatsRow({
    super.key,
    required this.stats,
  });

  final List<ProgressMiniStat> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: _StatCard(stat: stats[i])),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final ProgressMiniStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8DDFA).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Text(stat.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            stat.label,
            style: TextStyle(
              fontSize: 11,
              color: HomeTheme.textMuted.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: HomeTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
