import 'package:flutter/material.dart';
import '../../models/progress_models.dart';
import '../../theme/home_theme.dart';

class _StatusStyle {
  const _StatusStyle({
    required this.icon,
    required this.background,
    required this.accent,
  });

  final IconData icon;
  final Color background;
  final Color accent;
}

_StatusStyle _styleFor(ProgressRoutineStatus s) {
  switch (s) {
    case ProgressRoutineStatus.completed:
      return const _StatusStyle(
        icon: Icons.check_circle_rounded,
        background: Color(0xFFD4E4FF),
        accent: HomeTheme.actionBlue,
      );
    case ProgressRoutineStatus.later:
      return const _StatusStyle(
        icon: Icons.access_time_rounded,
        background: Color(0xFFFFE9D4),
        accent: HomeTheme.actionOrange,
      );
    case ProgressRoutineStatus.skipped:
      return const _StatusStyle(
        icon: Icons.skip_next_rounded,
        background: Color(0xFFFFE4E9),
        accent: HomeTheme.actionRose,
      );
    case ProgressRoutineStatus.pending:
      return const _StatusStyle(
        icon: Icons.circle_outlined,
        background: Color(0xFFF5F0FF),
        accent: HomeTheme.textMuted,
      );
  }
}

/// 상태별 루틴 섹션 (완료 / 나중에 / 스킵 / 대기)
class ProgressStatusSection extends StatelessWidget {
  const ProgressStatusSection({
    super.key,
    required this.group,
  });

  final ProgressStatusGroup group;

  @override
  Widget build(BuildContext context) {
    if (group.items.isEmpty) return const SizedBox.shrink();

    final st = _styleFor(group.status);
    final count = group.items.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: st.background.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: st.accent.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: st.accent.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(st.icon, color: st.accent, size: 22),
              const SizedBox(width: 8),
              Text(
                group.status.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: st.accent,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count개',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: st.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.items.map((r) => _RoutineChip(item: r)).toList(),
          ),
        ],
      ),
    );
  }
}

class _RoutineChip extends StatelessWidget {
  const _RoutineChip({required this.item});

  final ProgressRoutineItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.95),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 17)),
          const SizedBox(width: 6),
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: HomeTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.timeLabel,
            style: TextStyle(
              fontSize: 11,
              color: HomeTheme.textMuted.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}
