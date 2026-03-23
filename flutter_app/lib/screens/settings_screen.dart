import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF5F5),
              Color(0xFFFFF9E6),
              Color(0xFFF0F4FF),
            ],
          ),
        ),
        child: Stack(
          children: [
            // 서브틀한 배경 데코
            ..._buildSubtleDecorations(),

            SafeArea(
              child: Column(
                children: [
                  // 헤더
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/home'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB8A4C9).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFF8B7B9E),
                              size: 20,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          '설정',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF8B7B9E),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),

                  // 프로필 카드
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildProfileCard(),
                  ),
                  const SizedBox(height: 24),

                  // 설정 목록
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        _buildSectionTitle('알림 및 소리'),
                        _buildSettingsList([
                          _buildToggleItem(
                            Icons.notifications,
                            '푸시 알림',
                            const Color(0xFFFFB8C6),
                            _notificationsEnabled,
                            (value) => setState(
                                () => _notificationsEnabled = value),
                          ),
                          _buildToggleItem(
                            Icons.volume_up,
                            '알림 소리',
                            const Color(0xFFFFDDC5),
                            _soundEnabled,
                            (value) => setState(() => _soundEnabled = value),
                          ),
                        ]),
                        const SizedBox(height: 24),

                        _buildSectionTitle('기기 연동'),
                        _buildSettingsList([
                          _buildToggleItem(
                            Icons.watch,
                            'Apple Watch 연동',
                            const Color(0xFFD4E4FF),
                            _watchEnabled,
                            (value) => setState(() => _watchEnabled = value),
                          ),
                        ]),
                        const SizedBox(height: 24),

                        _buildSectionTitle('개인화'),
                        _buildSettingsList([
                          _buildNavigationItem(
                            Icons.emoji_emotions,
                            '캐릭터 설정',
                            const Color(0xFFFFE4E9),
                            () {},
                          ),
                          _buildNavigationItem(
                            Icons.palette,
                            '테마 설정',
                            const Color(0xFFE8DDFA),
                            () {},
                          ),
                        ]),
                        const SizedBox(height: 24),

                        _buildSectionTitle('지원'),
                        _buildSettingsList([
                          _buildNavigationItem(
                            Icons.mail_outline,
                            '문의하기',
                            const Color(0xFFD4C5F0),
                            () {},
                          ),
                          _buildInfoItem(
                            Icons.info_outline,
                            '버전 정보',
                            const Color(0xFFB8A4C9),
                            'v1.0.0',
                          ),
                        ]),
                        const SizedBox(height: 30),

                        // 푸터
                        const Center(
                          child: Column(
                            children: [
                              Text(
                                'Made with 💕',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFB8A4C9),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Routine Timer App',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFD4C5F0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.8),
            const Color(0xFFFFF9F5).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFE8DDFA).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB8A4C9).withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // 캐릭터 아바타
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -5 * _floatingController.value),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE4E9), Color(0xFFFFD4E0)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB8C6).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Text('🐻', style: TextStyle(fontSize: 36)),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7FDD8F),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),

          // 사용자 정보
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '나의 루틴 친구',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8B7B9E),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '오늘도 함께 해요! 🌟',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB8A4C9),
                  ),
                ),
              ],
            ),
          ),

          // 연속 일수 뱃지
          Column(
            children: [
              Text(
                '3',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFB8C6),
                ),
              ),
              const Text(
                '연속 일',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFB8A4C9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFFB8A4C9),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSettingsList(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8DDFA).withOpacity(0.3),
          width: 1,
        ),
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
                  color: const Color(0xFFE8DDFA).withOpacity(0.2),
                  indent: 16,
                  endIndent: 16,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8B7B9E),
                fontWeight: FontWeight.w500,
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8B7B9E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFB8A4C9),
              size: 20,
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8B7B9E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFB8A4C9).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8B7B9E),
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
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 28,
        decoration: BoxDecoration(
          gradient: value
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                )
              : null,
          color: value ? null : const Color(0xFFB8A4C9).withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
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
            opacity: 0.15,
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
