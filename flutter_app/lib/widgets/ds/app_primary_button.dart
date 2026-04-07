import 'package:flutter/material.dart';

import 'app_button.dart';

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
    return AppButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      variant: AppButtonVariant.primary,
    );
  }
}
