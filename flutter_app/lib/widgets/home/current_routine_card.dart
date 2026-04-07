import 'package:flutter/material.dart';
import '../../models/home_models.dart';
import '../../theme/home_theme.dart';

class CurrentRoutineCard extends StatelessWidget {
  const CurrentRoutineCard({
    super.key,
    required this.routine,
    this.next,
    this.isUpcoming = false,
  });

  final CurrentRoutine routine;
  final NextRoutine? next;

  /// true면 시간 슬롯 밖에서 보이는 "다가오는" 루틴
  final bool isUpcoming;

  static const _chipMuted = Color(0xFFD4E4FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: HomeTheme.accentPink.withValues(alpha: 0.46),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: HomeTheme.accentPink.withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: HomeTheme.accentPink.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isUpcoming ? '곧 시작하는 루틴' : '지금 가장 중요한 루틴',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.12,
                color: HomeTheme.textPrimary.withValues(alpha: 0.82),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE8DDFA).withValues(alpha: 0.55),
                      Colors.white.withValues(alpha: 0.95),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFE8DDFA).withValues(alpha: 0.45),
                  ),
                ),
                child: Center(
                  child:
                      Text(routine.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.35,
                        color: HomeTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${routine.startTime} — ${routine.endTime}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: HomeTheme.textMuted.withValues(alpha: 0.92),
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              (isUpcoming ? _chipMuted : HomeTheme.accentPink)
                                  .withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isUpcoming ? '다가오는 루틴' : '진행 중',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: HomeTheme.textMuted.withValues(alpha: 0.88),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isUpcoming ? '곧 할 일' : '지금 할 일',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.35,
              color: HomeTheme.textMuted.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            routine.memo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: HomeTheme.textPrimary.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.repeat_rounded,
                size: 15,
                color: HomeTheme.textMuted.withValues(alpha: 0.78),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  routine.repeatDays.join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: HomeTheme.textMuted.withValues(alpha: 0.82),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (next != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9F5).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: HomeTheme.accentPink.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '다음 루틴',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.35,
                      color: HomeTheme.textMuted.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(next!.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          next!.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.15,
                            color: HomeTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: HomeTheme.accentPink.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          next!.time,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: HomeTheme.textPrimary.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isUpcoming ? '시작 전 준비도' : '이 루틴 진행도',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: HomeTheme.textMuted.withValues(alpha: 0.68),
                ),
              ),
              Text(
                '${routine.progress}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: HomeTheme.textPrimary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: routine.progress / 100,
              minHeight: 7,
              backgroundColor: HomeTheme.textMuted.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                HomeTheme.accentPink.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
