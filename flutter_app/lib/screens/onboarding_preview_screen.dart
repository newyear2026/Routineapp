import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/onboarding/onboarding_preview_nav.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/ds.dart';
import '../widgets/settings/settings_list_items.dart';
import '../widgets/settings/settings_section.dart';

/// 스플래시·인트로·루틴·알림 온보딩 화면을 각각 또는 이어서 본다.
///
/// 이 허브의 모든 경로는 미리보기다. 온보딩 완료 플래그와 알림 설정을
/// 바꾸지 않는다. 첫 실행을 다시 타는 일은 설정의 「시작 안내 다시 보기」다.
class OnboardingPreviewScreen extends StatelessWidget {
  const OnboardingPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: AppScreenShell(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.commonBack,
                    onPressed: () => OnboardingPreviewNav.leaveHub(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.textPrimary,
                  ),
                  Expanded(
                    child: Text(
                      l10n.onboardingPreviewTitle,
                      style: AppTextStyles.titleScreen,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.onboardingPreviewBody,
              style: AppTextStyles.helper,
            ),
            const SizedBox(height: 24),
            SettingsSectionTitle(
              title: l10n.onboardingPreviewSectionScreens,
              icon: Icons.slideshow_rounded,
            ),
            SettingsList(children: [
              SettingsNavigationTile(
                icon: Icons.brightness_5_outlined,
                label: l10n.onboardingPreviewSplash,
                description: l10n.onboardingPreviewSplashDesc,
                onTap: () => context.push(OnboardingPreviewNav.splash),
              ),
              SettingsNavigationTile(
                icon: Icons.auto_stories_outlined,
                label: l10n.onboardingPreviewIntro,
                description: l10n.onboardingPreviewIntroDesc,
                onTap: () => context.push(OnboardingPreviewNav.intro),
              ),
              SettingsNavigationTile(
                icon: Icons.checklist_rounded,
                label: l10n.onboardingPreviewRoutine,
                description: l10n.onboardingPreviewRoutineDesc,
                onTap: () => context.push(OnboardingPreviewNav.routine),
              ),
              SettingsNavigationTile(
                icon: Icons.notifications_active_outlined,
                label: l10n.onboardingPreviewNotification,
                description: l10n.onboardingPreviewNotificationDesc,
                onTap: () => context.push(OnboardingPreviewNav.notification),
              ),
            ]),
            const SizedBox(height: 20),
            AppButton(
              key: const Key('onboarding-preview-full-flow'),
              label: l10n.onboardingPreviewFullFlow,
              icon: Icons.play_arrow_rounded,
              onPressed: () => context.push(OnboardingPreviewNav.splashFlow),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.onboardingPreviewFullFlowDesc,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
