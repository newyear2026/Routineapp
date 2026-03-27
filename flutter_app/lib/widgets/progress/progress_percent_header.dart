import 'package:flutter/material.dart';
import '../../theme/home_theme.dart';

/// 상단 원형 진행률 + 완료·남은·전체 요약
class ProgressPercentHeader extends StatelessWidget {
  const ProgressPercentHeader({
    super.key,
    required this.percent,
    required this.completedCount,
    required this.remainingCount,
    required this.totalCount,
  });

  final int percent;
  final int completedCount;
  final int remainingCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFFFF9F5)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE8DDFA).withValues(alpha: 0.45),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: HomeTheme.textMuted.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 168,
            height: 168,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 168,
                  height: 168,
                  child: CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 12,
                    backgroundColor:
                        HomeTheme.textMuted.withValues(alpha: 0.14),
                    valueColor:
                        const AlwaysStoppedAnimation(HomeTheme.accentPink),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        color: HomeTheme.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '오늘 진행률',
                      style: TextStyle(
                        fontSize: 12,
                        color: HomeTheme.textMuted.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _miniStat('완료', completedCount, HomeTheme.actionBlue),
              _miniStat('남은', remainingCount, HomeTheme.actionOrange),
              _miniStat('전체', totalCount, HomeTheme.textPrimary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: HomeTheme.textMuted,
          ),
        ),
      ],
    );
  }
}
