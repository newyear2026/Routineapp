import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';

class AppFieldMessage extends StatelessWidget {
  const AppFieldMessage({
    super.key,
    required this.message,
    this.isError = false,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: AppTextStyles.caption.copyWith(
        color: isError ? const Color(0xFFB14F67) : const Color(0xFF6A728A),
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
    );
  }
}
