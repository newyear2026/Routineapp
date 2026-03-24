import 'package:flutter/material.dart';
import '../ds/app_primary_button.dart';

/// @deprecated [AppPrimaryButton] 사용 권장
class PastelGradientButton extends StatelessWidget {
  const PastelGradientButton({
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
    return AppPrimaryButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
    );
  }
}
