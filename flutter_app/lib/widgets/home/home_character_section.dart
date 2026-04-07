import 'package:flutter/material.dart';
import '../../models/home_models.dart';
import '../../theme/home_theme.dart';

/// 보조 분위기 — 문구는 [HomeNowFocusBanner]에서 처리, 여기서는 캐릭터만 작게
class HomeCharacterSection extends StatelessWidget {
  const HomeCharacterSection({super.key, required this.character});

  final CharacterCopy character;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.82,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE4E9), Color(0xFFFFD4E0)],
              ),
              boxShadow: [
                BoxShadow(
                  color: HomeTheme.accentPink.withValues(alpha: 0.16),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child:
                  Text(character.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '오늘도 천천히 해봐요',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: HomeTheme.textMuted.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}
