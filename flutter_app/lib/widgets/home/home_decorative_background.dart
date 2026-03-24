import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 파스텔 분위기 배경 장식 (Home 전용)
class HomeDecorativeBackground extends StatelessWidget {
  const HomeDecorativeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ...List.generate(8, (i) => _FloatingEmoji(seed: i, emoji: '⭐')),
        ...List.generate(6, (i) => _FloatingEmoji(seed: i + 10, emoji: '✨')),
        ...List.generate(4, (i) => _FloatingEmoji(seed: i + 20, emoji: '💕')),
      ],
    );
  }
}

class _FloatingEmoji extends StatelessWidget {
  const _FloatingEmoji({required this.seed, required this.emoji});

  final int seed;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final r = math.Random(seed);
    final left = r.nextDouble() * 360;
    final top = r.nextDouble() * 720;
    final size = 12.0 + r.nextDouble() * 8;

    return Positioned(
      left: left,
      top: top,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 2000 + r.nextInt(1000)),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * math.sin(value * 2 * math.pi)),
            child: Opacity(
              opacity: 0.2 + 0.4 * math.sin(value * math.pi),
              child: Text(emoji, style: TextStyle(fontSize: size)),
            ),
          );
        },
      ),
    );
  }
}
