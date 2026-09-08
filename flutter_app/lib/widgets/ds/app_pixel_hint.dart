import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AppPixelHint extends StatelessWidget {
  const AppPixelHint(
      {super.key, required this.message, this.isError = false, this.title});
  final String message;
  final bool isError;
  final String? title;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isError ? const Color(0xFFFFF0EC) : AppColors.orbitSurface,
          border: Border.all(
              color: isError ? AppColors.dangerText : AppColors.textMuted,
              width: 2),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (title != null) ...[
            Text(title!, style: AppTextStyles.bodyStrong),
            const SizedBox(height: 4)
          ],
          Text(message,
              style: AppTextStyles.caption.copyWith(
                  color: isError ? AppColors.dangerText : AppColors.textMuted)),
        ]),
      );
}
