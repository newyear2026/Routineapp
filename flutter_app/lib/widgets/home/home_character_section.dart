import 'package:flutter/material.dart';
import '../../models/home_models.dart';
import '../../theme/home_theme.dart';

class HomeCharacterSection extends StatelessWidget {
  const HomeCharacterSection({super.key, required this.character});

  final CharacterCopy character;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFE4E9), Color(0xFFFFD4E0)],
            ),
            boxShadow: [
              BoxShadow(
                color: HomeTheme.accentPink.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(character.emoji, style: const TextStyle(fontSize: 40)),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: HomeTheme.accentPink.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: HomeTheme.accentPink.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: HomeTheme.textPrimary),
              children: [
                const TextSpan(text: '지금은 '),
                TextSpan(
                  text: '${character.highlightEmoji} ${character.highlightRoutineName}',
                  style: const TextStyle(
                    color: HomeTheme.accentPink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const TextSpan(text: ' 시간!'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
