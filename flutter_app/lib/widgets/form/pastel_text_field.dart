import 'package:flutter/material.dart';
import '../ds/app_labeled_text_field.dart';

/// @deprecated [AppLabeledTextField] 사용 권장
class PastelTextField extends StatelessWidget {
  const PastelTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.errorText,
    this.helperText,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return AppLabeledTextField(
      label: label,
      hint: hint,
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      errorText: errorText,
      helperText: helperText,
    );
  }
}
