import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/home_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _notificationsEnabled = true;
  bool _watchEnabled = false;
  bool _soundEnabled = true;

  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: HomeTheme.pageGradient),
        child: Stack(
          children: [
            ..._buildSubtleDecorations(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.go('/home'),
                            borderRadius: BorderRadius.circular(20),
                            child: Ink(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: HomeTheme.textMuted.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: HomeTheme.textPrimary,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          '설정',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: HomeTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 42),
                      ],
                    ),
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
                        _buildSectionTitle('알림 및 소리', Icons.notifications_active_rounded),
                        _buildSettingsList([
                          _buildToggleItem(
                            Icons.notifications_rounded,
                            '푸시 알림',
                            HomeTheme.accentPink,
                            _notificationsEnabled,
                            (value) =>
                                setState(() => _notificationsEnabled = value),
                          ),
                          _buildToggleItem(
                            Icons.volume_up_rounded,
                            '알림 소리',
                            const Color(0xFFFFDDC5),
                            _soundEnabled,
                            (value) => setState(() => _soundEnabled = value),
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
                          ),
                        ]),
                        const SizedBox(height: 26),
                        _buildSectionTitle('개인화', Icons.auto_awesome_rounded),
                        _buildSettingsList([
                          _buildNavigationItem(
                            Icons.emoji_emotions_rounded,
                            '캐릭터 설정',
                            const Color(0xFFFFE4E9),
                            () {},
                          ),
                          _buildNavigationItem(
                            Icons.palette_rounded,
                            '테마 설정',
                            const Color(0xFFE8DDFA),
                            () {},
                          ),
                        ]),
                        const SizedBox(height: 26),
                        _buildSectionTitle('지원', Icons.support_rounded),
                        _buildSettingsList([
                          _buildNavigationItem(
                            Icons.mail_outline_rounded,
                            '문의하기',
                            const Color(0xFFD4C5F0),
                            () {},
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
                                'Made with 💕',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: HomeTheme.textMuted.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Routine Timer App',
                                style: TextStyle(
                                  fontSize: 11,
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
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.92),
            const Color(0xFFFFF9F5).withValues(alpha: 0.88),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: HomeTheme.accentPink.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: HomeTheme.textPrimary.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
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
                            child: Text('🐻', style: TextStyle(fontSize: 40)),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF7FDD8F),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
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
                    const Text(
                      '나의 루틴 친구',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.35,
                        color: HomeTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '오늘도 함께해요',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: HomeTheme.textMuted.withValues(alpha: 0.92),
                      ),
                    ),
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
              boxShadow: [
                BoxShadow(
                  color: HomeTheme.accentPink.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text(
                  '🔥',
                  style: TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '연속 루틴',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: HomeTheme.textMuted.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '3일째 이어가는 중이에요',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: HomeTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: HomeTheme.accentPink.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '3',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          letterSpacing: -0.5,
                          color: HomeTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '연속일',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: HomeTheme.textMuted.withValues(alpha: 0.85),
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
    );
  }

  Widget _profileChip(IconData icon, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: HomeTheme.textPrimary.withValues(alpha: 0.75)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: HomeTheme.textPrimary,
            ),
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
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(icon, color: color.withValues(alpha: 0.95), size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: HomeTheme.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ),
          _buildToggleSwitch(value, onChanged, color),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: HomeTheme.accentPink.withValues(alpha: 0.12),
        highlightColor: HomeTheme.textMuted.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: color.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(icon, color: color.withValues(alpha: 0.95), size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: HomeTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: HomeTheme.textMuted.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: HomeTheme.textMuted.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: HomeTheme.textMuted.withValues(alpha: 0.75),
                  size: 22,
                ),
              ),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(icon, color: color.withValues(alpha: 0.95), size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: HomeTheme.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ),
          Container(
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: HomeTheme.textPrimary.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch(
    bool value,
    ValueChanged<bool> onChanged,
    Color color,
  ) {
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
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
              width: value ? 1.5 : 1.5,
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

  List<Widget> _buildSubtleDecorations() {
    return [
      ...List.generate(4, (i) {
        return Positioned(
          left: (i * 100.0) % 400,
          top: (i * 200.0) % 800,
          child: Opacity(
            opacity: 0.12,
            child: Text(
              '✨',
              style: TextStyle(fontSize: 10.0 + i * 2),
            ),
          ),
        );
      }),
    ];
  }
}
