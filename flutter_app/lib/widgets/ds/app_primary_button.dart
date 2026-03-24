import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// 그라데이션 **주요 버튼** (저장·완료·큰 CTA)
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.button),
            gradient: AppColors.primaryButtonGradient,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4E4FF).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.actionBlue, size: 22),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label, style: AppTextStyles.button),
            ],
          ),
        ),
      ),
    );
  }
}
