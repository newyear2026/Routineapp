import 'package:flutter/material.dart';

import 'app_pixel_hint.dart';

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
      child: AppPixelHint(message: message, isError: isError),
    );
  }
}
