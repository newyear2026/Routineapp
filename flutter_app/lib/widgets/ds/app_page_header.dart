import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_icon_button.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final leading = onBack != null
        ? AppIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: onBack,
            tooltip: '뒤로',
            size: 40,
          )
        : const SizedBox(width: 40);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 12, 12),
      child: Row(
        children: [
          leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleSection.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.45,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 40,
            child: trailing == null ? null : Center(child: trailing),
          ),
        ],
      ),
    );
  }
}
