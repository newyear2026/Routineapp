import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../application/services/notification_onboarding_actions.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_preset.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/ds.dart';

class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bellController;
  final NotificationOnboardingActions _actions =
      NotificationOnboardingActions();

  @override
  void initState() {
    super.initState();
    _bellController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bellController.dispose();
    super.dispose();
  }

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
    final theme = context.appTheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: theme.pageGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    const Text('알림 설정', style: AppTextStyles.titleScreen),
                    const SizedBox(height: 24),
                    AnimatedBuilder(
                      animation: _bellController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _bellController.value * 0.3 - 0.15,
                          child: Container(
                            width: 132,
                            height: 132,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              gradient: AppColors.highlightGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.warning
                                      .withValues(alpha: 0.28),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text('🔔', style: TextStyle(fontSize: 66)),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 36),
                    const Text(
                      '알림을 받으시겠어요?',
                      style: AppTextStyles.hero,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '루틴 시간에 맞춰 가볍게 알려드릴게요.\n바로 완료하거나 잠시 미룰 수 있어요.',
                      style: AppTextStyles.helper,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildNotificationExample(
                      '🌅',
                      '07:00',
                      '기상 시간이에요!',
                      '상쾌한 아침을 시작해봐요',
                    ),
                    const SizedBox(height: 12),
                    _buildNotificationExample(
                      '📚',
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
                      height: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationExample(
    String emoji,
    String time,
    String title,
    String description,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: AppColors.accentPink.withValues(alpha: 0.22),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
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
