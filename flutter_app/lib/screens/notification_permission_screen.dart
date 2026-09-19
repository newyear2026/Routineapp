import '../widgets/ds/pixel_decoration.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../application/routine_app_controller.dart';
import '../application/services/exact_alarm_service.dart';
import '../application/services/notification_onboarding_actions.dart';
import '../domain/onboarding/onboarding_preview_nav.dart';
import '../domain/models/routine_icon_id.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/routine_palette.dart';
import '../widgets/ds/app_pixel_switch.dart';
import '../widgets/ds/ds.dart';

class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({
    super.key,
    this.preview = false,
    this.previewFlow = false,
  });

  final bool preview;
  final bool previewFlow;

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  final NotificationOnboardingActions _actions =
      NotificationOnboardingActions();
  final ExactAlarmService _exactAlarm = ExactAlarmService.instance;

  Future<void> _goHome() async {
    if (!mounted) return;
    context.go('/home');
  }

  void _leavePreview() {
    OnboardingPreviewNav.finish(
      context,
      flow: widget.previewFlow,
    );
  }

  Future<void> _allowNotifications() async {
    if (widget.preview) {
      if (!mounted) return;
      _leavePreview();
      return;
    }
    await _actions.completeWithSystemPermissionRequest();
    // 알림을 쓰기로 한 사람에게만 정확 알람을 묻는다. 앱이 직접 켤 수 없는
    // 권한이라 시스템 설정으로 보내는 것 말고 방법이 없다. 이미 켜져 있으면
    // 화면을 띄우지 않는다.
    // 컨트롤러는 권한을 받기 전에 이미 로드됐다. 그때는 알림이 꺼져 있어
    // 아무것도 예약되지 않았으므로, 허용한 지금 다시 걸어야 한다.
    // 이게 없으면 온보딩을 마쳐도 앱을 다시 열기 전까지 알림이 오지 않는다.
    await _resyncNotifications();

    // 시스템 설정보다 홈 이동을 먼저 한다. 설정 화면은 자기 태스크에서 떠서
    // 뒤로 가기가 앱이 아니라 런처로 나가는데, 그때 온보딩에 머물러 있으면
    // 사용자가 앱을 다시 열었을 때 같은 화면을 또 만난다.
    await _goHome();
    if (!await _exactAlarm.canScheduleExactAlarms()) {
      await _exactAlarm.openSettings();
    }
  }

  Future<void> _resyncNotifications() async {
    if (!mounted) return;
    await context.read<RoutineAppController>().resyncNotifications();
  }

  Future<void> _skipNotifications() async {
    if (widget.preview) {
      if (!mounted) return;
      _leavePreview();
      return;
    }
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
              if (widget.preview)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: l10n.commonBack,
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.textPrimary,
                  ),
                ),
              const SizedBox(height: 12),
              Text(l10n.permTitle, style: AppTextStyles.caption),
              const SizedBox(height: 24),
              SizedBox(
                key: const Key('notification-permission-hero'),
                height: 148,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned(
                      left: 24,
                      top: 18,
                      child: PixelCloud(width: 48),
                    ),
                    const Positioned(
                      right: 28,
                      top: 28,
                      child: PixelCloud(width: 40),
                    ),
                    const Positioned(
                      left: 56,
                      top: 8,
                      child: PixelSpark(size: 12),
                    ),
                    const Positioned(
                      right: 52,
                      top: 12,
                      child: PixelSpark(size: 14),
                    ),
                    const PixelDecoration(asset: 'bell', size: 108),
                  ],
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
                RoutineIconId.sun,
                RoutinePalette.coral,
                '07:00',
                l10n.permSampleWakeTitle,
                l10n.permSampleWakeBody,
              ),
              const SizedBox(height: 12),
              _buildNotificationExample(
                RoutineIconId.book,
                RoutinePalette.lavender,
                '09:00',
                l10n.permSampleStudyTitle,
                l10n.permSampleStudyBody,
              ),
              const SizedBox(height: 16),
              _buildExactAlarmNote(l10n),
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

  Widget _buildExactAlarmNote(AppLocalizations l10n) {
    return Container(
      key: const Key('exact-alarm-note'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.zero,
        color: AppColors.orbitPrimary.withValues(alpha: 0.07),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIcon(Icons.settings_outlined, color: AppColors.orbitPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.permExactTitle,
                  style: AppTextStyles.smallStrong,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.permExactBody,
                  style: AppTextStyles.caption.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationExample(
    RoutineIconId icon,
    Color routineColor,
    String time,
    String title,
    String description,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          RoutineMark(icon: icon, color: routineColor, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: AppTextStyles.bodyStrong),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppTextStyles.smallStrong,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
          const IgnorePointer(
            child: AppPixelSwitch(value: true, onChanged: null),
          ),
        ],
      ),
    );
  }
}
