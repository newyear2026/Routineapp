import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  void _allowNotifications() {
    // 실제로는 알림 권한 요청 로직
    context.go('/routine-setup');
  }

  void _skipNotifications() {
    context.go('/routine-setup');
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
              Color(0xFFFFF8F3),
              Color(0xFFFFF5F8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 상단 텍스트
                const SizedBox(height: 20),
                const Text(
                  '알림 설정',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF8B7B9E),
                  ),
                ),
                const SizedBox(height: 24),

                // 중앙 벨 아이콘
                AnimatedBuilder(
                  animation: _bellController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _bellController.value * 0.3 - 0.15,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFE9D4),
                              Color(0xFFFFDDC5),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFDDC5).withOpacity(0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '🔔',
                            style: TextStyle(fontSize: 70),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 50),

                // 제목
                const Text(
                  '알림을 받으시겠어요?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B7B9E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // 설명
                const Text(
                  '루틴 시간마다 귀여운 알림으로\n잊지 않도록 도와드릴게요 💕',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFFB8A4C9),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // 알림 예시 카드들
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
                const SizedBox(height: 32),

                // 허용 버튼
                GestureDetector(
                  onTap: _allowNotifications,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4E4FF), Color(0xFFC5D5F0)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4E4FF).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '알림 허용하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 나중에 하기 버튼
                TextButton(
                  onPressed: _skipNotifications,
                  child: const Text(
                    '나중에 설정할게요',
                    style: TextStyle(
                      color: Color(0xFFB8A4C9),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8DDFA).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: const Color(0xFFFFE4E9).withOpacity(0.5),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB8A4C9),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B7B9E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB8A4C9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
