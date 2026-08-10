import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// 입력 아래 인라인 메시지 — 에러는 스낵바보다 이 컴포넌트를 먼저 쓴다
/// (UI_STANDARDS 3).
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
    return Semantics(
      liveRegion: isError,
      child: Text(
        message,
        style: AppTextStyles.caption.copyWith(
          color: isError ? AppColors.dangerText : AppColors.textMuted,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }
}
