import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../ds/ds.dart';

class HomeBottomActions extends StatelessWidget {
  const HomeBottomActions({
    super.key,
    required this.completeLabel,
    this.onComplete,
    this.onLater,
    this.onSkip,
    this.primaryEnabled = true,
    this.secondaryEnabled = true,
    this.disabledReason,
    this.isProcessing = false,
  });

  final String completeLabel;
  final VoidCallback? onComplete;
  final VoidCallback? onLater;
  final VoidCallback? onSkip;

  /// false면 완료 버튼 비활성(시간대 밖 등)
  final bool primaryEnabled;

  /// false면 나중에/건너뛰기 비활성
  final bool secondaryEnabled;
  final String? disabledReason;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    assert(
      !primaryEnabled || onComplete != null,
      'primaryEnabled가 true이면 onComplete 콜백이 필요합니다.',
    );
    assert(
      !secondaryEnabled || (onLater != null && onSkip != null),
      'secondaryEnabled가 true이면 onLater/onSkip 콜백이 모두 필요합니다.',
    );
    final primaryInteractive = primaryEnabled && !isProcessing;
    final secondaryInteractive = secondaryEnabled && !isProcessing;
    return Column(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: primaryInteractive ? 1 : 0.48,
          child: AppButton(
            label: isProcessing ? '처리 중...' : completeLabel,
            icon: isProcessing ? null : Icons.check_circle_rounded,
            isLoading: isProcessing,
            onPressed: primaryInteractive ? onComplete : null,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: secondaryInteractive ? 1 : 0.52,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _LaterButton(
                  onTap: secondaryInteractive ? onLater : null,
                ),
              ),
              const SizedBox(width: 8),
              _SkipLinkButton(
                onTap: secondaryInteractive ? onSkip : null,
              ),
            ],
          ),
        ),
        if ((!primaryInteractive || !secondaryInteractive) &&
            disabledReason != null) ...[
          const SizedBox(height: 10),
          Text(
            disabledReason!,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted.withValues(alpha: 0.88),
            ),
          ),
        ],
      ],
    );
  }
}

class _LaterButton extends StatelessWidget {
  const _LaterButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Colors.white.withValues(alpha: 0.7),
            border: Border.all(
              color: AppColors.orbitBorder.withValues(alpha: 0.9),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule_rounded,
                color: AppColors.textMuted.withValues(alpha: 0.88),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '나중에',
                style: AppTextStyles.bodyStrong.copyWith(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 가장 약한 액션 — 텍스트로 의미를 분명히
class _SkipLinkButton extends StatelessWidget {
  const _SkipLinkButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.skip_next_rounded,
                size: 17,
                color: AppColors.textMuted.withValues(alpha: enabled ? 0.58 : 0.42),
              ),
              const SizedBox(width: 4),
              Text(
                '건너뛰기',
                style: AppTextStyles.captionTight.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted.withValues(alpha: enabled ? 0.7 : 0.56),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
