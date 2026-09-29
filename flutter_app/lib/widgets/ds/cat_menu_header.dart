import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import 'animated_cat.dart';

/// Keeps the illustration in its own space, including at large text scales.
class CatMenuHeader extends StatelessWidget {
  const CatMenuHeader({
    super.key,
    this.caption,
    required this.title,
    required this.subtitle,
    required this.pose,
    this.catKey,
    this.decorationAsset,
    this.decorationKey,
  });
  final String? caption;
  final String title;
  final String subtitle;
  final CatPose pose;
  final Key? catKey;
  final String? decorationAsset;
  final Key? decorationKey;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final compact = box.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(16) > 20;
        final text =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (caption != null) ...[
            Text(caption!, style: AppTextStyles.caption),
            const SizedBox(height: 2),
          ],
          Text(title, style: AppTextStyles.titleScreen),
          const SizedBox(height: 3),
          Text(subtitle, style: AppTextStyles.caption),
        ]);
        final cat = SizedBox(
            key: catKey,
            width: compact ? 80 : 104,
            height: compact ? 80 : 104,
            child: AnimatedCat(pose: pose));
        final content = compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(alignment: Alignment.centerRight, child: cat),
                  text,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: text),
                  const SizedBox(width: 12),
                  cat,
                ],
              );
        if (decorationAsset == null) return content;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              key: decorationKey,
              left: compact ? -12 : -24,
              right: compact ? -12 : -24,
              top: compact ? -12 : -42,
              child: IgnorePointer(
                child: Image.asset(
                  decorationAsset!,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            content,
          ],
        );
      });
}
