import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../application/routine_app_controller.dart';
import '../application/services/notification_permission_service.dart';
import '../application/services/routine_notification_service.dart';
import '../data/local/notification_preferences_storage.dart';
import '../data/local/onboarding_local_storage.dart';
import '../domain/settings/notification_permission_status.dart';
import '../domain/settings/notification_preferences.dart';
import '../theme/app_theme_preset.dart';
import '../theme/home_theme.dart';
import '../widgets/ds/ds.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final RoutineNotificationService _routineNotifications =
      RoutineNotificationService();

  bool _notificationsEnabled = false;
  bool _watchEnabled = false;
  bool _soundEnabled = true;

  late AnimationController _floatingController;

  Future<void> _loadNotificationPrefs() async {
    final prefs = await NotificationPreferencesStorage.load();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.notificationsEnabled;
      _soundEnabled = prefs.soundEnabled;
    });
  }

  Future<void> _onPushChanged(bool wantOn) async {
    final controller = context.read<RoutineAppController>();
    if (!wantOn) {
      final current = await NotificationPreferencesStorage.load();
      await NotificationPreferencesStorage.save(
        NotificationPreferences(
          notificationsEnabled: false,
          permissionStatus: current.permissionStatus,
          soundEnabled: false,
        ),
      );
      if (!mounted) return;
      setState(() {
        _notificationsEnabled = false;
        _soundEnabled = false;
      });
      await _routineNotifications.syncAll(controller.routines);
      return;
    }

    final granted = await NotificationPermissionService.instance
        .requestPostNotificationsPermission();
    if (!mounted) return;
    if (granted) {
      await NotificationPreferencesStorage.save(
        const NotificationPreferences(
          notificationsEnabled: true,
          permissionStatus: NotificationPermissionStatus.granted,
          soundEnabled: true,
        ),
      );
      setState(() {
        _notificationsEnabled = true;
        _soundEnabled = true;
      });
      await _routineNotifications.syncAll(controller.routines);
    } else {
      await NotificationPreferencesStorage.save(
        const NotificationPreferences(
          notificationsEnabled: false,
          permissionStatus: NotificationPermissionStatus.denied,
          soundEnabled: false,
        ),
      );
      setState(() {
        _notificationsEnabled = false;
        _soundEnabled = false;
      });
      await _routineNotifications.syncAll(controller.routines);
    }
  }

  Future<void> _onSoundChanged(bool value) async {
    if (!_notificationsEnabled) return;
    final controller = context.read<RoutineAppController>();
    final current = await NotificationPreferencesStorage.load();
    await NotificationPreferencesStorage.save(
      current.copyWith(soundEnabled: value),
    );
    if (!mounted) return;
    setState(() => _soundEnabled = value);
    await _routineNotifications.syncAll(controller.routines);
  }

  @override
  void initState() {
    super.initState();
    _loadNotificationPrefs();
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RoutineAppController>();
    return Scaffold(
      body: AppScreenShell(
        child: Column(
          children: [
            AppPageHeader(
              title: '설정',
              subtitle: '알림, 테마, 기기 연동을 한곳에서 관리하세요',
              onBack: () => context.go('/home'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildProfileCard(),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                children: [
                  _buildSectionTitle(
                    '알림 및 소리',
                    Icons.notifications_active_rounded,
                  ),
                  _buildSettingsList([
                    _buildToggleItem(
                      Icons.notifications_rounded,
                      '푸시 알림',
                      HomeTheme.accentPink,
                      _notificationsEnabled,
                      (value) => _onPushChanged(value),
                    ),
                    _buildToggleItem(
                      Icons.volume_up_rounded,
                      '알림 소리',
                      const Color(0xFFFFDDC5),
                      _notificationsEnabled && _soundEnabled,
                      (value) => _onSoundChanged(value),
                      switchEnabled: _notificationsEnabled,
                      description: '푸시 알림이 켜져 있을 때만 사용할 수 있어요',
                    ),
                  ]),
                  const SizedBox(height: 26),
                  _buildSectionTitle('기기 연동', Icons.devices_rounded),
                  _buildSettingsList([
                    _buildToggleItem(
                      Icons.watch_rounded,
                      'Apple Watch 연동',
                      const Color(0xFFD4E4FF),
                      _watchEnabled,
                      (value) => setState(() => _watchEnabled = value),
                      description: '기본 토글만 먼저 연결되어 있어요',
                    ),
                  ]),
                  const SizedBox(height: 26),
                  _buildSectionTitle('개인화', Icons.auto_awesome_rounded),
                  _buildSettingsList([
                    _buildNavigationItem(
                      Icons.replay_rounded,
                      '온보딩 다시 보기',
                      const Color(0xFFFFE9D4),
                      () {
                        OnboardingLocalStorage.resetForReplay().then((_) {
                          if (!context.mounted) return;
                          context.go('/onboarding');
                        });
                      },
                      description: '앱의 첫 안내 플로우를 다시 볼 수 있어요',
                    ),
                    _buildNavigationItem(
                      Icons.emoji_emotions_rounded,
                      '캐릭터 설정',
                      const Color(0xFFFFE4E9),
                      null,
                      statusLabel: '준비 중',
                      description: '다음 업데이트에서 캐릭터를 고를 수 있어요',
                    ),
                    _buildNavigationItem(
                      Icons.palette_rounded,
                      '테마 설정',
                      const Color(0xFFE8DDFA),
                      null,
                      statusLabel: '활성',
                      description: '앱 전체에 적용할 테마 프리셋을 고를 수 있어요',
                    ),
                  ]),
                  const SizedBox(height: 14),
                  _ThemePresetSection(
                    currentThemeId: controller.themeId,
                    onSelected: controller.updateTheme,
                  ),
                  const SizedBox(height: 26),
                  _buildSectionTitle('지원', Icons.support_rounded),
                  _buildSettingsList([
                    _buildNavigationItem(
                      Icons.widgets_outlined,
                      'Medium 위젯 미리보기',
                      const Color(0xFFFFE9D4),
                      () => context.push('/widget-medium-preview'),
                      description: '위젯 톤과 정보를 미리 확인할 수 있어요',
                    ),
                    _buildNavigationItem(
                      Icons.mail_outline_rounded,
                      '문의하기',
                      const Color(0xFFD4C5F0),
                      null,
                      statusLabel: '준비 중',
                      description: '지원 채널 연결 전이에요',
                    ),
                    _buildInfoItem(
                      Icons.info_outline_rounded,
                      '버전 정보',
                      const Color(0xFFB8A4C9),
                      'v1.0.0',
                    ),
                  ]),
                  const SizedBox(height: 28),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Designed for your daily rhythm',
                          style: AppTextStyles.caption.copyWith(
                            color: HomeTheme.textMuted.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Routine Timer App',
                          style: AppTextStyles.captionTight.copyWith(
                            color: HomeTheme.textMuted.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return AppCard(
      variant: AppCardVariant.elevated,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: _floatingController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -4 * _floatingController.value),
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFE4E9), Color(0xFFFFD4E0)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: HomeTheme.accentPink.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Center(
                            child: Icon(
                              Icons.track_changes_rounded,
                              size: 36,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘의 루틴 상태',
                      style: AppTextStyles.titleSection.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    const Text('앱 흐름과 진행 상태를 확인하세요', style: AppTextStyles.label),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _profileChip(
                          Icons.auto_graph_rounded,
                          '루틴 진행 중',
                          HomeTheme.accentPink,
                        ),
                        _profileChip(
                          Icons.mood_rounded,
                          '기분 좋은 하루',
                          const Color(0xFFD4C5F0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  HomeTheme.accentPink.withValues(alpha: 0.28),
                  const Color(0xFFE8DDFA).withValues(alpha: 0.45),
                ],
              ),
              border: Border.all(
                color: HomeTheme.accentPink.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('연속 루틴', style: AppTextStyles.caption),
                      const SizedBox(height: 2),
                      Text(
                        '3일째 이어가는 중이에요',
                        style: AppTextStyles.bodyStrong.copyWith(fontSize: 15),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: HomeTheme.accentPink.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '3',
                        style: AppTextStyles.statMedium.copyWith(
                          fontSize: 26,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text('연속일', style: AppTextStyles.captionTight),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileChip(IconData icon, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: HomeTheme.textPrimary.withValues(alpha: 0.75),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.captionTight.copyWith(
              fontWeight: FontWeight.w700,
              color: HomeTheme.textPrimary.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  HomeTheme.accentPink,
                  HomeTheme.accentPink.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            icon,
            size: 17,
            color: HomeTheme.textMuted.withValues(alpha: 0.75),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: AppTextStyles.titleSection.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8DDFA).withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: HomeTheme.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: const Color(0xFFE8DDFA).withValues(alpha: 0.35),
                  indent: 14,
                  endIndent: 14,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToggleItem(
    IconData icon,
    String label,
    Color color,
    bool value,
    ValueChanged<bool> onChanged, {
    bool switchEnabled = true,
    String? description,
  }) {
    return Opacity(
      opacity: switchEnabled ? 1.0 : 0.45,
      child: AppSettingsTile(
        icon: icon,
        label: label,
        accent: color,
        description: description,
        enabled: switchEnabled,
        trailing: _buildToggleSwitch(
          value,
          onChanged,
          color,
          enabled: switchEnabled,
        ),
      ),
    );
  }

  Widget _buildNavigationItem(
    IconData icon,
    String label,
    Color color,
    VoidCallback? onTap, {
    String? statusLabel,
    String? description,
  }) {
    final enabled = onTap != null;
    return AppSettingsTile(
      icon: icon,
      label: label,
      accent: color,
      description: description,
      onTap: onTap,
      enabled: enabled,
      statusLabel: statusLabel,
      statusTone: AppStatusBadgeTone.readySoon,
      trailing: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: HomeTheme.textMuted.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: HomeTheme.textMuted.withValues(alpha: 0.12),
          ),
        ),
        child: Icon(
          enabled ? Icons.chevron_right_rounded : Icons.remove_rounded,
          color: HomeTheme.textMuted.withValues(alpha: 0.75),
          size: 22,
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    Color color,
    String value,
  ) {
    return AppSettingsTile(
      icon: icon,
      label: label,
      accent: color,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: HomeTheme.textMuted.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: HomeTheme.textMuted.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          value,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: HomeTheme.textPrimary.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSwitch(
    bool value,
    ValueChanged<bool> onChanged,
    Color color, {
    bool enabled = true,
  }) {
    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? () => onChanged(!value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 52,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: value
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withValues(alpha: 0.82),
                    ],
                  )
                : null,
            color: value ? null : const Color(0xFFE3DCE8),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: value
                  ? color.withValues(alpha: 0.45)
                  : const Color(0xFFC9C0D4).withValues(alpha: 0.65),
              width: 1.5,
            ),
            boxShadow: value
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: value
                        ? color.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.12),
                    blurRadius: value ? 6 : 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemePresetSection extends StatelessWidget {
  const _ThemePresetSection({
    required this.currentThemeId,
    required this.onSelected,
  });

  final String currentThemeId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '테마 프리셋',
            style: AppTextStyles.titleSection.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            '배경과 버튼, 강조색이 함께 바뀝니다.',
            style: AppTextStyles.caption.copyWith(height: 1.35),
          ),
          const SizedBox(height: 14),
          Column(
            children: AppThemePreset.all.map((preset) {
              final selected = preset.id == currentThemeId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSelected(preset.id),
                    borderRadius: BorderRadius.circular(18),
                    child: Ink(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? preset.accentLavender.withValues(alpha: 0.85)
                              : AppColors.border.withValues(alpha: 0.45),
                          width: selected ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          ...preset.previewColors.map(
                            (color) => Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              preset.label,
                              style: AppTextStyles.bodyStrong.copyWith(
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (selected)
                            const AppStatusBadge(
                              label: '사용 중',
                              tone: AppStatusBadgeTone.success,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
