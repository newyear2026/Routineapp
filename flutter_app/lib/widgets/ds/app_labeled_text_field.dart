import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// 라벨 + 둥근 **텍스트 입력** (Routine Add 등)
class AppLabeledTextField extends StatelessWidget {
  const AppLabeledTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.65),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.55),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.45),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: const BorderSide(
                color: AppColors.accentPink,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
