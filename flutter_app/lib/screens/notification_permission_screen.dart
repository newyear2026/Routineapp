import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../application/services/notification_onboarding_actions.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/routine_palette.dart';
import '../widgets/ds/ds.dart';

class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  final NotificationOnboardingActions _actions =
      NotificationOnboardingActions();

  Future<void> _goHome() async {
    if (!mounted) return;
    context.go('/home');
  }

  Future<void> _allowNotifications() async {
    await _actions.completeWithSystemPermissionRequest();
    await _goHome();
  }

  Future<void> _skipNotifications() async {
    await _actions.deferNotificationSetupLater();
    await _goHome();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: AppScreenShell(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(l10n.permTitle, style: AppTextStyles.caption),
              const SizedBox(height: 24),
              // 상시 회전 애니메이션은 design_system_v2 7.2 '장식용 모션 금지'에 어긋난다.
              // 주황 그라데이션도 앱 어디에도 없는 톤이라 브랜드색으로 맞춘다.
              Container(
                key: const Key('notification-permission-hero'),
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: AppColors.orbitPrimary.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  size: 52,
                  color: AppColors.orbitPrimary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                l10n.permHeadline,
                style: AppTextStyles.titleScreen,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.permBody,
                style: AppTextStyles.helper,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              _buildNotificationExample(
                RoutinePalette.coral,
                '07:00',
                l10n.permSampleWakeTitle,
                l10n.permSampleWakeBody,
              ),
              const SizedBox(height: 12),
              _buildNotificationExample(
                RoutinePalette.lavender,
                '14:00',
                l10n.permSampleStudyTitle,
                l10n.permSampleStudyBody,
              ),
              const SizedBox(height: 28),
              AppButton(
                label: l10n.permAllow,
                onPressed: _allowNotifications,
              ),
              const SizedBox(height: 12),
              AppButton(
                label: l10n.permLater,
                onPressed: _skipNotifications,
                variant: AppButtonVariant.ghost,
                expand: false,
                height: 44,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationExample(
    Color routineColor,
    String time,
    String title,
    String description,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: routineColor,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: routineColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(time, style: AppTextStyles.caption),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
