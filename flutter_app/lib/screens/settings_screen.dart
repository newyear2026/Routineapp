import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../application/routine_app_controller.dart';
import '../application/settings/settings_controller.dart';
import '../data/local/onboarding_local_storage.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/ds.dart';
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
            const Text('설정', style: AppTextStyles.titleScreen),
            const SizedBox(height: 3),
            const Text('알림과 앱 모양을 한곳에서 관리하세요',
                style: AppTextStyles.caption),
            const SizedBox(height: 24),
            if (settings.errorMessage != null) ...[
              _SettingsErrorBanner(
                message: settings.errorMessage!,
                onRetry: settings.load,
                onDismiss: settings.clearError,
              ),
              const SizedBox(height: 16),
            ],
            const SettingsSectionTitle(
              title: '알림 및 소리',
              icon: Icons.notifications_active_rounded,
            ),
            SettingsList(children: [
              SettingsToggleTile(
                icon: Icons.notifications_rounded,
                label: '푸시 알림',
                value: settings.notificationsEnabled,
                enabled: controlsEnabled,
                onChanged: (value) => settings.setNotificationsEnabled(
                  value,
                  appController.routines,
                ),
              ),
              SettingsToggleTile(
                icon: Icons.volume_up_rounded,
                label: '알림 소리',
                value: settings.soundEnabled,
                enabled: controlsEnabled && settings.notificationsEnabled,
                description: '푸시 알림이 켜져 있을 때만 쓸 수 있어요',
                onChanged: (value) => settings.setSoundEnabled(
                  value,
                  appController.routines,
                ),
              ),
            ]),
            const SizedBox(height: 26),
            const SettingsSectionTitle(
              title: '개인화',
              icon: Icons.auto_awesome_rounded,
            ),
            SettingsList(children: [
              SettingsNavigationTile(
                icon: Icons.replay_rounded,
                label: '온보딩 다시 보기',
                description: '앱의 첫 안내 플로우를 다시 볼 수 있어요',
                onTap: () async {
                  await OnboardingLocalStorage.resetForReplay();
                  if (context.mounted) context.go('/onboarding');
                },
              ),
              const SettingsNavigationTile(
                icon: Icons.emoji_emotions_rounded,
                label: '캐릭터 설정',
                statusLabel: '준비 중',
                description: '다음 업데이트에서 캐릭터를 고를 수 있어요',
              ),
            ]),
            const SizedBox(height: 14),
            const ThemePresetSection(),
            const SizedBox(height: 26),
            const SettingsSectionTitle(
              title: '지원',
              icon: Icons.support_rounded,
            ),
            SettingsList(children: [
              SettingsNavigationTile(
                icon: Icons.widgets_outlined,
                label: '위젯 미리보기',
                description: '홈 화면에 놓을 위젯 모습을 확인할 수 있어요',
                onTap: () => context.push('/widget-medium-preview'),
              ),
              const SettingsNavigationTile(
                icon: Icons.mail_outline_rounded,
                label: '문의하기',
                statusLabel: '준비 중',
                description: '지원 채널 연결 전이에요',
              ),
              const SettingsInfoTile(
                icon: Icons.info_outline_rounded,
                label: '버전 정보',
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
    return Semantics(
      liveRegion: true,
      label: '설정 오류: $message',
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.dangerText),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: AppTextStyles.caption)),
            TextButton(onPressed: onRetry, child: const Text('재시도')),
            IconButton(
              tooltip: '오류 메시지 닫기',
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
