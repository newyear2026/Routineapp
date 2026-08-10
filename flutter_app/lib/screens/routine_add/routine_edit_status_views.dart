import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/ds/ds.dart';

/// 편집할 루틴을 불러오는 동안 보여주는 화면.
class RoutineEditLoadingView extends StatelessWidget {
  const RoutineEditLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          variant: AppCardVariant.elevated,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              const SizedBox(height: 16),
              const Text(
                '루틴 정보를 불러오는 중이에요',
                style: AppTextStyles.bodyStrong,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '기존 설정을 확인한 뒤 편집 화면을 안정적으로 보여드릴게요.',
                style: AppTextStyles.caption.copyWith(height: 1.45),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 편집할 루틴을 찾지 못했을 때의 화면.
class RoutineEditLoadFailedView extends StatelessWidget {
  const RoutineEditLoadFailedView({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          variant: AppCardVariant.elevated,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 30,
                color: AppColors.dangerText,
              ),
              const SizedBox(height: 14),
              const Text(
                '편집할 루틴을 찾을 수 없어요',
                style: AppTextStyles.bodyStrong,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '삭제되었거나 아직 로드되지 않은 상태일 수 있어요. 홈으로 돌아가 다시 확인해 주세요.',
                style: AppTextStyles.caption.copyWith(height: 1.45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: '뒤로 가기',
                icon: Icons.arrow_back_rounded,
                onPressed: onBack,
                variant: AppButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
