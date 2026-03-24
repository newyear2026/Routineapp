import 'package:flutter/material.dart';
import '../../models/home_models.dart';
import '../../theme/home_theme.dart';

class CurrentRoutineCard extends StatelessWidget {
  const CurrentRoutineCard({
    super.key,
    required this.routine,
    required this.next,
  });

  final CurrentRoutine routine;
  final NextRoutine next;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE8DDFA).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: HomeTheme.textMuted.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE8DDFA).withValues(alpha: 0.5),
                      Colors.white.withValues(alpha: 0.95),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFE8DDFA).withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: Text(routine.emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            routine.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: HomeTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: HomeTheme.accentPink.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            '진행 중',
                            style: TextStyle(fontSize: 11, color: HomeTheme.textMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${routine.startTime} — ${routine.endTime}',
                      style: const TextStyle(fontSize: 12, color: HomeTheme.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: routine.repeatDays
                          .map(
                            (d) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4E4FF).withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                d,
                                style: const TextStyle(fontSize: 10, color: HomeTheme.textMuted),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '오늘 진행도',
                          style: TextStyle(fontSize: 11, color: HomeTheme.textMuted),
                        ),
                        Text(
                          '${routine.progress}%',
                          style: const TextStyle(fontSize: 11, color: HomeTheme.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: routine.progress / 100,
                        minHeight: 8,
                        backgroundColor: HomeTheme.textMuted.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation(HomeTheme.accentPink),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            routine.memo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: HomeTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE8DDFA).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '다음 루틴',
                  style: TextStyle(fontSize: 11, color: HomeTheme.textMuted),
                ),
                const SizedBox(width: 8),
                Text(next.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    next.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: HomeTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8DDFA).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    next.time,
                    style: const TextStyle(fontSize: 12, color: HomeTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
