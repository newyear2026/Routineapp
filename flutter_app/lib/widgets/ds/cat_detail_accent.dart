import 'package:flutter/material.dart';
import 'animated_cat.dart';

/// A reserved, non-interactive space above detail content and dialog text.
class CatDetailAccent extends StatelessWidget {
  const CatDetailAccent({super.key, required this.pose, this.size = 72});
  final CatPose pose;
  final double size;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child:
            SizedBox(width: size, height: size, child: AnimatedCat(pose: pose)),
      );
}
