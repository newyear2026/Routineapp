import 'package:flutter/material.dart';
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
    return Scaffold(
      body: AppScreenShell(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text('알림 설정', style: AppTextStyles.caption),
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
              const Text(
                '알림을 받으시겠어요?',
                style: AppTextStyles.titleScreen,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                '루틴 시간에 맞춰 가볍게 알려드릴게요.\n알림을 확인한 뒤 앱에서 완료하거나 잠시 미룰 수 있어요.',
                style: AppTextStyles.helper,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              _buildNotificationExample(
                RoutinePalette.coral,
                '07:00',
                '기상 시간이에요!',
                '상쾌한 아침을 시작해봐요',
              ),
              const SizedBox(height: 12),
              _buildNotificationExample(
                RoutinePalette.lavender,
                '14:00',
                '공부 시간이에요!',
                '집중해서 학습해봐요',
              ),
              const SizedBox(height: 28),
              AppButton(
                label: '알림 허용하기',
                onPressed: _allowNotifications,
              ),
              const SizedBox(height: 12),
              AppButton(
                label: '나중에 설정할게요',
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
