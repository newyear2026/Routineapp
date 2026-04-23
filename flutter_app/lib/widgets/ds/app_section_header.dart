import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.eyebrow,
    this.centered = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String? eyebrow;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final crossAxisAlignment =
        centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!,
                  textAlign: centered ? TextAlign.center : TextAlign.start,
                  style: AppTextStyles.captionTight.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.textMuted.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                title,
                textAlign: centered ? TextAlign.center : TextAlign.start,
                style: AppTextStyles.titleSection.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.45,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  textAlign: centered ? TextAlign.center : TextAlign.start,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}
