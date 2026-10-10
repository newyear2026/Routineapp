import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../application/settings/settings_controller.dart';
import '../domain/models/routine.dart';
import '../domain/settings/notification_preferences.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_pixel_style.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/app_pixel_switch.dart';
import '../widgets/ds/ds.dart';

/// 설정의 기존 컨트롤러를 공유해 돌아갈 때도 변경된 값을 그대로 보여준다.
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({
    super.key,
    required this.controller,
    required this.routines,
  });

  final SettingsController controller;
  final List<Routine> routines;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final l10n = AppLocalizations.of(context);
          final enabled = !controller.isLoading && !controller.isUpdating;
          final ios = defaultTargetPlatform == TargetPlatform.iOS;
          // iOS에는 예약 알림의 진동만 독립적으로 켜는 공개 API가 없다.
          // 실제로 보장할 수 없는 '진동만' 선택을 제공하지 않는다.
          final mode = ios && !controller.soundEnabled
              ? RoutineNotificationMode.visualOnly
              : controller.notificationMode;
          final modes = RoutineNotificationMode.values.where((value) =>
              !ios || value != RoutineNotificationMode.vibrationOnly);
          final status = switch (mode) {
            RoutineNotificationMode.soundAndVibration =>
              l10n.notificationStatusSound,
            RoutineNotificationMode.vibrationOnly =>
              l10n.notificationStatusVibration,
            RoutineNotificationMode.visualOnly => l10n.notificationStatusVisual,
          };
          return Scaffold(
            backgroundColor: AppColors.pageBackground,
            bottomNavigationBar: OrbitBottomNavigation(
              currentIndex: 3,
              onHome: () => context.go('/home'),
              onProgress: () => context.go('/progress'),
              onRoutines: () => context.go('/routines'),
              onSettings: () => Navigator.of(context).maybePop(),
            ),
            body: SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(l10n.notificationSettingsTitle,
                            style: AppTextStyles.hero.copyWith(fontSize: 28))),
                    IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const AppIcon(Icons.close_rounded,
                          color: AppColors.textMuted, size: 24),
                    ),
                  ]),
                  Text(l10n.notificationSettingsSubtitle,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 32),
                  Text(l10n.notificationStartSection,
                      style: AppTextStyles.bodyStrong
                          .copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 14),
                  Container(
                    decoration: appSurfaceDecoration(),
                    padding: const EdgeInsets.all(2),
                    child: ClipPath(
                      clipper: const ShapeBorderClipper(
                          shape: AppPixelStyle.plainShape),
                      child: Column(children: [
                        for (final value in modes) ...[
                          if (value != modes.first)
                            const Divider(
                                height: 1,
                                color: AppColors.orbitBorder,
                                indent: 16,
                                endIndent: 16),
                          _ModeRow(
                            mode: value,
                            selected: mode == value,
                            onTap: enabled
                                ? () => controller.setNotificationMode(
                                    value, routines, l10n)
                                : null,
                          ),
                        ],
                      ]),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(children: [
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.completionHapticTitle,
                            style: AppTextStyles.bodyStrong),
                        const SizedBox(height: 8),
                        Text(l10n.completionHapticDesc,
                            style: AppTextStyles.caption),
                      ],
                    )),
                    const SizedBox(width: 10),
                    AppPixelSwitch(
                      key: const Key('completion-haptic-toggle'),
                      label: l10n.completionHapticTitle,
                      value: controller.completionHapticEnabled,
                      onChanged: enabled
                          ? controller.setCompletionHapticEnabled
                          : null,
                    ),
                  ]),
                  const SizedBox(height: 18),
                  const Divider(height: 1, color: AppColors.orbitBorder),
                  if (!controller.notificationsEnabled) ...[
                    const SizedBox(height: 16),
                    Text(l10n.notificationDisabledHint,
                        style: AppTextStyles.caption),
                    Row(children: [
                      Expanded(
                          child: Text(l10n.settingsPush,
                              style: AppTextStyles.bodyStrong)),
                      AppPixelSwitch(
                        label: l10n.settingsPush,
                        value: false,
                        onChanged: enabled
                            ? (value) => controller.setNotificationsEnabled(
                                value, routines, l10n)
                            : null,
                      ),
                    ]),
                  ],
                  if (controller.error != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                        liveRegion: true,
                        child: Text(l10n.errorSaveNotifications,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.dangerText))),
                  ],
                  const SizedBox(height: 22),
                  Icon(_modeIcon(mode),
                      size: 25, color: AppColors.orbitPrimary),
                  const SizedBox(height: 12),
                  Semantics(
                      liveRegion: true,
                      child: Text(status,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyStrong)),
                  const SizedBox(height: 22),
                  AppButton(
                    label: l10n.notificationPreviewAction,
                    isLoading: controller.isUpdating,
                    onPressed: enabled &&
                            controller.notificationsEnabled &&
                            !kIsWeb
                        ? () async {
                            final success =
                                await controller.previewNotification(l10n);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(success
                                    ? l10n.notificationPreviewSent
                                    : l10n.notificationPreviewFailed)));
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.notificationSnoozeSettingsHint,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption),
                  const SizedBox(height: 12),
                  Text(
                      ios
                          ? l10n.notificationIosVibrationHint
                          : l10n.notificationSystemSettingsHint,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(fontSize: 12)),
                ],
              ),
            ),
          );
        },
      );
}

IconData _modeIcon(RoutineNotificationMode mode) => switch (mode) {
      RoutineNotificationMode.soundAndVibration => Icons.notifications_rounded,
      RoutineNotificationMode.vibrationOnly => Icons.vibration_rounded,
      RoutineNotificationMode.visualOnly => Icons.chat_bubble_outline_rounded,
    };

class _ModeRow extends StatelessWidget {
  const _ModeRow(
      {required this.mode, required this.selected, required this.onTap});
  final RoutineNotificationMode mode;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (title, subtitle) = switch (mode) {
      RoutineNotificationMode.soundAndVibration => (
          l10n.notificationModeSound,
          l10n.notificationModeSoundDesc
        ),
      RoutineNotificationMode.vibrationOnly => (
          l10n.notificationModeVibration,
          l10n.notificationModeVibrationDesc
        ),
      RoutineNotificationMode.visualOnly => (
          l10n.notificationModeVisual,
          l10n.notificationModeVisualDesc
        ),
    };
    return Semantics(
      label: '$title. $subtitle',
      checked: selected,
      inMutuallyExclusiveGroup: true,
      enabled: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: selected ? const Color(0xFFF1ECFF) : AppColors.orbitSurface,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(children: [
              Container(
                width: 44,
                height: 48,
                color: const Color(0xFFEDE7FF),
                child: Icon(_modeIcon(mode),
                    color: AppColors.orbitPrimary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: AppTextStyles.bodyStrong.copyWith(fontSize: 18)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: AppTextStyles.caption),
                  ])),
              const SizedBox(width: 12),
              Container(
                width: 23,
                height: 23,
                padding: const EdgeInsets.all(3),
                decoration: ShapeDecoration(
                    shape: AppPixelStyle.shape(
                        color: selected
                            ? AppColors.orbitPrimary
                            : AppColors.textMuted,
                        step: 2,
                        steps: 4)),
                child: selected
                    ? DecoratedBox(
                        decoration: ShapeDecoration(
                            color: AppColors.orbitPrimary,
                            shape: AppPixelStyle.shape(
                                color: AppColors.orbitPrimary,
                                step: 2,
                                steps: 3)))
                    : null,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
