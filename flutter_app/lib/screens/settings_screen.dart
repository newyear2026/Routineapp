import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../application/routine_app_controller.dart';
import '../application/settings/settings_controller.dart';
import '../data/local/onboarding_local_storage.dart';
import '../domain/settings/settings_error.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/ds.dart';
import '../widgets/settings/language_settings_tile.dart';
import '../widgets/settings/settings_list_items.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/theme_preset_section.dart';

/// 설정 화면은 섹션 배치와 화면 전환만 담당한다.
/// 알림 설정의 로드·저장·권한 요청은 [SettingsController]에 둔다.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsController()..load(),
      child: const _SettingsScreenContent(),
    );
  }
}

class _SettingsScreenContent extends StatelessWidget {
  const _SettingsScreenContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appController = context.watch<RoutineAppController>();
    final settings = context.watch<SettingsController>();
    final controlsEnabled = !settings.isLoading && !settings.isUpdating;

    return Scaffold(
      bottomNavigationBar: OrbitBottomNavigation(
        currentIndex: 3,
        onHome: () => context.go('/home'),
        onProgress: () => context.go('/progress'),
        onRoutines: () => context.go('/routines'),
        onSettings: () {},
      ),
      body: AppScreenShell(
        // 탭 목적지이므로 뒤로가기를 두지 않고, 다른 탭과 같은 좌측 정렬 헤더를 쓴다.
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 28),
          children: [
            Text(l10n.settingsTitle, style: AppTextStyles.titleScreen),
            const SizedBox(height: 3),
            Text(l10n.settingsSubtitle, style: AppTextStyles.caption),
            const SizedBox(height: 24),
            if (settings.error != null) ...[
              _SettingsErrorBanner(
                message: _errorMessage(l10n, settings.error!),
                onRetry: settings.load,
                onDismiss: settings.clearError,
              ),
              const SizedBox(height: 16),
            ],
            SettingsSectionTitle(
              title: l10n.settingsSectionNotifications,
              icon: Icons.notifications_active_rounded,
            ),
            SettingsList(children: [
              SettingsToggleTile(
                icon: Icons.notifications_rounded,
                label: l10n.settingsPush,
                value: settings.notificationsEnabled,
                enabled: controlsEnabled,
                onChanged: (value) => settings.setNotificationsEnabled(
                  value,
                  appController.routines,
                  l10n,
                ),
              ),
              SettingsToggleTile(
                icon: Icons.volume_up_rounded,
                label: l10n.settingsSound,
                value: settings.soundEnabled,
                enabled: controlsEnabled && settings.notificationsEnabled,
                description: l10n.settingsSoundDesc,
                onChanged: (value) => settings.setSoundEnabled(
                  value,
                  appController.routines,
                  l10n,
                ),
              ),
            ]),
            const SizedBox(height: 26),
            SettingsSectionTitle(
              title: l10n.settingsSectionPersonalize,
              icon: Icons.auto_awesome_rounded,
            ),
            SettingsList(children: [
              // 언어는 이 섹션에서 유일하게 지금 동작하는 설정이라 맨 위에 둔다.
              const LanguageSettingsTile(),
              SettingsNavigationTile(
                icon: Icons.replay_rounded,
                label: l10n.settingsReplayOnboarding,
                description: l10n.settingsReplayOnboardingDesc,
                onTap: () async {
                  await OnboardingLocalStorage.resetForReplay();
                  if (context.mounted) context.go('/onboarding');
                },
              ),
              SettingsNavigationTile(
                icon: Icons.emoji_emotions_rounded,
                label: l10n.settingsCharacter,
                statusLabel: l10n.commonComingSoon,
                description: l10n.settingsCharacterDesc,
              ),
            ]),
            const SizedBox(height: 14),
            const ThemePresetSection(),
            const SizedBox(height: 26),
            SettingsSectionTitle(
              title: l10n.settingsSectionSupport,
              icon: Icons.support_rounded,
            ),
            SettingsList(children: [
              SettingsNavigationTile(
                icon: Icons.widgets_outlined,
                label: l10n.settingsWidgetPreview,
                description: l10n.settingsWidgetPreviewDesc,
                onTap: () => context.push('/widget-medium-preview'),
              ),
              SettingsNavigationTile(
                icon: Icons.mail_outline_rounded,
                label: l10n.settingsContact,
                statusLabel: l10n.commonComingSoon,
                description: l10n.settingsContactDesc,
              ),
              SettingsInfoTile(
                icon: Icons.info_outline_rounded,
                label: l10n.settingsVersion,
                value: 'v1.0.0',
              ),
            ]),
            const SizedBox(height: 28),
            Center(
              child: Text(
                'Routine Timer',
                style: AppTextStyles.captionTight.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _errorMessage(AppLocalizations l10n, SettingsError error) {
  switch (error) {
    case SettingsError.load:
      return l10n.errorLoadSettings;
    case SettingsError.saveNotifications:
      return l10n.errorSaveNotifications;
    case SettingsError.saveSound:
      return l10n.errorSaveSound;
  }
}

class _SettingsErrorBanner extends StatelessWidget {
  const _SettingsErrorBanner({
    required this.message,
    required this.onRetry,
    required this.onDismiss,
  });

  final String message;
  final Future<void> Function() onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      label: l10n.settingsError(message),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.dangerText),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: AppTextStyles.caption)),
            TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
            IconButton(
              tooltip: l10n.settingsErrorDismiss,
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
