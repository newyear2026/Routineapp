import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/ds/ds.dart';

/// 편집할 루틴을 불러오는 동안 보여주는 화면.
class RoutineEditLoadingView extends StatelessWidget {
  const RoutineEditLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              Text(
                l10n.routineLoadingTitle,
                style: AppTextStyles.bodyStrong,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.routineLoadingBody,
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
    final l10n = AppLocalizations.of(context);
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
              Text(
                l10n.routineMissingTitle,
                style: AppTextStyles.bodyStrong,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.routineMissingBody,
                style: AppTextStyles.caption.copyWith(height: 1.45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: l10n.commonGoBack,
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
