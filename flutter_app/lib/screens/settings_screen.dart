import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_optional_provider.dart';
import '../application/release/release_announcements.dart';
import '../application/routine_app_controller.dart';
import '../application/services/store_review_launcher.dart';
import '../application/update/app_updates_controller.dart';
import '../application/settings/settings_controller.dart';
import '../domain/onboarding/onboarding_preview_nav.dart';
import '../domain/settings/settings_error.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../domain/utils/app_date_formats.dart';
import '../widgets/ds/ds.dart';
import '../widgets/settings/current_pack_card.dart';
import '../widgets/settings/language_settings_tile.dart';
import '../widgets/settings/settings_list_items.dart';
import '../widgets/settings/settings_section.dart';

/// 설정 화면은 섹션 배치와 화면 전환만 담당한다.
/// 알림 설정의 로드·저장·권한 요청은 [SettingsController]에 둔다.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    this.openStoreReview = openPlayStoreReview,
    this.showStoreReview,
  });

  final StoreReviewLauncher openStoreReview;

  /// 비워 두면 [storeReviewAvailable]을 따른다. 테스트가 플랫폼과 무관하게
  /// 행을 켜고 끌 수 있도록 열어 둔다.
  final bool? showStoreReview;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsController()..load(),
      child: _SettingsScreenContent(
        openStoreReview: openStoreReview,
        showStoreReview: showStoreReview ?? storeReviewAvailable,
      ),
    );
  }
}

class _SettingsScreenContent extends StatelessWidget {
  const _SettingsScreenContent({
    required this.openStoreReview,
    required this.showStoreReview,
  });

  final StoreReviewLauncher openStoreReview;
  final bool showStoreReview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appController = context.watch<RoutineAppController>();
    final settings = context.watch<SettingsController>();
    final controlsEnabled = !settings.isLoading && !settings.isUpdating;
    // 프로바이더가 없으면 null이다 — 테스트나 갤러리가 이 화면만 띄운 경우다.
    // 그때 행은 **없는** 것이고, 눌러도 답하지 않는 죽은 행이 있는 것이 아니다.
    final updates = context.maybeWatch<AppUpdates>();
    final announcements = context.maybeWatch<ReleaseAnnouncements>();

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
            _SettingsSkyHeader(
              caption: AppDateFormats.monthDayWeekday(
                context,
                appController.now,
              ),
              title: l10n.settingsTitle,
              subtitle: l10n.settingsSubtitle,
            ),
            const SizedBox(height: 18),
            const CurrentPackCard(),
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
                icon: Icons.slideshow_outlined,
                label: l10n.settingsOnboardingPreview,
                description: l10n.settingsOnboardingPreviewDesc,
                onTap: () => context.push('/onboarding-preview'),
              ),
              SettingsNavigationTile(
                icon: Icons.replay_rounded,
                label: l10n.settingsReplayOnboarding,
                description: l10n.settingsReplayOnboardingDesc,
                onTap: () => _confirmReplayOnboarding(context),
              ),
            ]),
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
              if (showStoreReview)
                SettingsNavigationTile(
                  icon: Icons.star_outline_rounded,
                  label: l10n.settingsReview,
                  description: l10n.settingsReviewDesc,
                  onTap: () => _openStoreReview(context),
                ),
              // 물어볼 스토어가 없는 빌드에서는 행 자체를 빼야 한다. 두면
              // 무엇을 눌러도 «최신 버전이에요»라고 답한다.
              if (updates != null && updates.canCheck)
                SettingsNavigationTile(
                  icon: Icons.system_update_alt_rounded,
                  label: l10n.settingsCheckUpdate,
                  description: _updateCheckDescription(l10n, updates),
                  // 확인 중에도 살려 둔다. 컨트롤러가 겹친 호출을 버리므로
                  // 비활성으로 만들 이유가 없고, 그러면 화살표가 사라져 줄이
                  // 눌릴 때마다 흔들린다.
                  onTap: () => updates.refresh(force: true),
                ),
              if (announcements != null)
                SettingsNavigationTile(
                  icon: Icons.auto_awesome_rounded,
                  // 업데이트 안내와 색을 나눈다. 그쪽은 요청이라 행동색을 쓰고
                  // 이쪽은 알림이다.
                  accent: AppColors.orbitAccent,
                  label: l10n.settingsReleaseNotes,
                  description: l10n.settingsReleaseNotesDesc,
                  // 점이 아니라 글자다. 스크린리더는 점을 읽지 못한다.
                  statusLabel: announcements.hasUnreadNotes
                      ? l10n.settingsReleaseNotesUnread
                      : null,
                  onTap: () => context.push('/release-notes'),
                ),
              SettingsInfoTile(
                icon: Icons.info_outline_rounded,
                label: l10n.settingsVersion,
                // 플랫폼이 알려 주지 않으면 줄표다. 여기 상수를 적어 두면 실제
                // 버전이 그것을 지나친 뒤에도 틀린 값이 권위 있어 보인다.
                value: announcements?.version?.displayLabel ?? '—',
              ),
            ]),
            const SizedBox(height: 28),
            Center(
              child: Text(
                l10n.appName,
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

  Future<void> _openStoreReview(BuildContext context) async {
    final opened = await openStoreReview();
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).settingsReviewOpenFailed),
        ),
      );
  }

  Future<void> _confirmReplayOnboarding(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dialogL10n = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(dialogL10n.settingsReplayOnboardingConfirmTitle),
          content: Text(dialogL10n.settingsReplayOnboardingConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(dialogL10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(dialogL10n.settingsReplayOnboardingConfirmAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    // 다시 보기는 어디까지나 읽기 전용 미리보기다. 완료 플래그를 초기화해
    // 실제 첫 실행 경로로 보내면 추천 루틴 저장 단계도 다시 실행된다.
    // 화면 재생과 초기 데이터 설정을 경로 수준에서 분리한다.
    context.push(OnboardingPreviewNav.splashFlow);
  }
}

class _SettingsSkyHeader extends StatelessWidget {
  const _SettingsSkyHeader({
    required this.caption,
    required this.title,
    required this.subtitle,
  });

  final String caption;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            key: const Key('settings-sky-decoration'),
            right: -6,
            top: -32,
            child: IgnorePointer(
              child: Image.asset(
                'assets/decorations/settings-sky.png',
                width: 164,
                height: 100,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
                excludeFromSemantics: true,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(caption, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(title, style: AppTextStyles.titleScreen),
              const SizedBox(height: 3),
              Text(subtitle, style: AppTextStyles.caption),
            ],
          ),
        ],
      );
}

/// «업데이트 확인» 행이 지금 무엇을 말해야 하는가.
String _updateCheckDescription(AppLocalizations l10n, AppUpdates updates) {
  if (updates.isChecking) return l10n.settingsCheckUpdateBusy;
  if (updates.pending != null) return l10n.settingsCheckUpdateAvailable;
  return l10n.settingsCheckUpdateUpToDate;
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
