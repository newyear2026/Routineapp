import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import 'animated_cat.dart';

/// Keeps the illustration in its own space, including at large text scales.
class CatMenuHeader extends StatelessWidget {
  const CatMenuHeader(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.pose});
  final String title;
  final String subtitle;
  final CatPose pose;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final compact = box.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(16) > 20;
        final text =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTextStyles.titleScreen),
          const SizedBox(height: 3),
          Text(subtitle, style: AppTextStyles.caption),
        ]);
        final cat = SizedBox(
            width: compact ? 80 : 104,
            height: compact ? 80 : 104,
            child: AnimatedCat(pose: pose));
        if (compact) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(alignment: Alignment.centerRight, child: cat),
                text
              ]);
        }
        return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [Expanded(child: text), const SizedBox(width: 12), cat]);
      });
}
