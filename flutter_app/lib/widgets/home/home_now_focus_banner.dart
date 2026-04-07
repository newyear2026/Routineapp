import 'package:flutter/material.dart';
import '../../models/home_models.dart';
import '../../theme/home_theme.dart';

/// 홈 최상단 — "지금 무엇을 해야 하는지" 한눈에 (캐릭터보다 먼저 읽히도록)
class HomeNowFocusBanner extends StatelessWidget {
  const HomeNowFocusBanner({super.key, required this.character, this.compact = false});

  final CharacterCopy character;
  final bool compact;

  @override
  Widget build(BuildContext context) {
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
            Colors.white.withValues(alpha: 0.92),
            HomeTheme.accentPink.withValues(alpha: 0.22),
            const Color(0xFFE8DDFA).withValues(alpha: 0.35),
          ],
        ),
        border: Border.all(
          color: HomeTheme.accentPink.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: HomeTheme.accentPink.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 42 : 48,
            height: compact ? 42 : 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  HomeTheme.accentPink.withValues(alpha: 0.35),
                  Colors.white.withValues(alpha: 0.95),
                ],
              ),
              border: Border.all(
                color: HomeTheme.accentPink.withValues(alpha: 0.35),
              ),
            ),
            child: Center(
              child: Text(
                character.highlightEmoji,
                style: TextStyle(fontSize: compact ? 22 : 26),
              ),
            ),
          ),
          SizedBox(width: compact ? 12 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '현재 집중 루틴',
                  style: TextStyle(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: HomeTheme.textMuted.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 3),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      height: 1.25,
                      color: HomeTheme.textPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: character.highlightRoutineName,
                        style: TextStyle(
                          fontSize: compact ? 21 : 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: HomeTheme.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: compact ? '에 집중할 차례예요' : ' 시간이에요',
                        style: TextStyle(
                          fontSize: compact ? 15 : 19,
                          fontWeight: FontWeight.w700,
                          color: HomeTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
