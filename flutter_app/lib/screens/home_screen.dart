import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int completedRoutines = 3;
  final int totalRoutines = 8;

  late AnimationController _floatingController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = '${now.month}월 ${now.day}일';
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final dayOfWeek = weekdays[now.weekday % 7];

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
            // 배경 데코레이션
            _buildFloatingDecorations(),

            // 메인 콘텐츠
            SafeArea(
              child: Column(
                children: [
                  // 헤더
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 날짜 & 인사
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$dateString $dayOfWeek요일',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFB8A4C9),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '좋은 오후예요 👋',
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: Color(0xFF8B7B9E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            // 액션 버튼들
                            Row(
                              children: [
                                _buildActionButton(
                                  Icons.trending_up,
                                  const Color(0xFFFFB8C6),
                                  () => context.go('/progress'),
                                ),
                                const SizedBox(width: 8),
                                _buildActionButton(
                                  Icons.settings,
                                  const Color(0xFFD4C5F0),
                                  () => context.go('/settings'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 진행률 바
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '오늘의 진행',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFB8A4C9),
                                  ),
                                ),
                                Text(
                                  '$completedRoutines/$totalRoutines',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8B7B9E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: completedRoutines / totalRoutines,
                                minHeight: 8,
                                backgroundColor:
                                    const Color(0xFFB8A4C9).withOpacity(0.15),
                                valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFFFFB8C6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 메인 콘텐츠
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // 캐릭터 & 말풍선
                          _buildCharacterWithBubble(),
                          const SizedBox(height: 30),

                          // 원형 시계
                          CircularRoutineClock(
                            currentHour: now.hour,
                            currentMinute: now.minute,
                          ),
                          const SizedBox(height: 30),

                          // 완료 버튼
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                _buildCompleteButton(),
                                const SizedBox(height: 12),
                                
                                // 나중에 & 스킵 버튼
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSecondaryButton(
                                        '나중에',
                                        Icons.access_time,
                                        const Color(0xFFFFE9D4),
                                        const Color(0xFFD9A57B),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildSecondaryButton(
                                      '',
                                      Icons.skip_next,
                                      const Color(0xFFFFE4E9),
                                      const Color(0xFFD99BB0),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // 다음 루틴 카드
                                _buildNextRoutineCard(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
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

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildCharacterWithBubble() {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -10 * _floatingController.value),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE4E9), Color(0xFFFFD4E0)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB8C6).withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🐻', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFB8C6).withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB8C6).withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B7B9E),
                    ),
                    children: [
                      TextSpan(text: '지금은 '),
                      TextSpan(
                        text: '📚 공부',
                        style: TextStyle(
                          color: Color(0xFFFFB8C6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(text: ' 시간!'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompleteButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          completedRoutines = (completedRoutines + 1).clamp(0, totalRoutines);
        });
      },
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD4E4FF), Color(0xFFC5D5F0)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4E4FF).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Color(0xFF6B8BC9), size: 24),
            SizedBox(width: 12),
            Text(
              '공부 완료하기',
              style: TextStyle(
                color: Color(0xFF6B8BC9),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
    String label,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 48,
        padding: label.isEmpty ? const EdgeInsets.symmetric(horizontal: 20) : null,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgColor, bgColor.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 20),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNextRoutineCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8DDFA).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Text(
                '다음 루틴',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB8A4C9),
                ),
              ),
              SizedBox(width: 8),
              Text('☕', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                '휴식',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8B7B9E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8DDFA).withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '16:00',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFB8A4C9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingDecorations() {
    return Stack(
      children: [
        ...List.generate(8, (i) => _buildFloatingEmoji('⭐', i)),
        ...List.generate(6, (i) => _buildFloatingEmoji('✨', i + 10)),
        ...List.generate(4, (i) => _buildFloatingEmoji('💕', i + 20)),
      ],
    );
  }

  Widget _buildFloatingEmoji(String emoji, int seed) {
    final random = math.Random(seed);
    return Positioned(
      left: random.nextDouble() * 400,
      top: random.nextDouble() * 800,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: 2000 + random.nextInt(1000)),
        curve: Curves.easeInOut,
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * math.sin(value * 2 * math.pi)),
            child: Opacity(
              opacity: 0.2 + (0.4 * math.sin(value * math.pi)),
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: 12.0 + random.nextDouble() * 8,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 원형 시계 위젯
class CircularRoutineClock extends StatelessWidget {
  final int currentHour;
  final int currentMinute;

  const CircularRoutineClock({
    super.key,
    required this.currentHour,
    required this.currentMinute,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 원형 시계 배경
          CustomPaint(
            size: const Size(280, 280),
            painter: ClockPainter(currentHour, currentMinute),
          ),

          // 중앙 시간 표시
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${currentHour.toString().padLeft(2, '0')}:${currentMinute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8B7B9E),
                ),
              ),
              const Text(
                '현재 시간',
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
}

class ClockPainter extends CustomPainter {
  final int currentHour;
  final int currentMinute;

  ClockPainter(this.currentHour, this.currentMinute);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 배경 원
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 10, bgPaint);

    // 루틴 세그먼트
    final routines = [
      {'hour': 6, 'emoji': '🌅', 'color': const Color(0xFFFFE4E9)},
      {'hour': 9, 'emoji': '🍳', 'color': const Color(0xFFFFE9D4)},
      {'hour': 12, 'emoji': '🍱', 'color': const Color(0xFFFFFDDC5)},
      {'hour': 15, 'emoji': '☕', 'color': const Color(0xFFD4E4FF)},
      {'hour': 18, 'emoji': '🍽️', 'color': const Color(0xFFFFE4E9)},
      {'hour': 23, 'emoji': '🌙', 'color': const Color(0xFFD4C5F0)},
    ];

    for (int i = 0; i < routines.length; i++) {
      final routine = routines[i];
      final nextRoutine = routines[(i + 1) % routines.length];

      final startAngle =
          ((routine['hour'] as int) / 24) * 2 * math.pi - math.pi / 2;
      final sweepAngle = (((nextRoutine['hour'] as int) -
                  (routine['hour'] as int)) /
              24) *
          2 *
          math.pi;

      final paint = Paint()
        ..color = (routine['color'] as Color).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 25;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 25),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // 시침
    final hourAngle =
        ((currentHour % 12) * 30 + currentMinute * 0.5) * math.pi / 180 -
            math.pi / 2;
    final hourHandPaint = Paint()
      ..color = const Color(0xFFFFB8C6)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        center.dx + 50 * math.cos(hourAngle),
        center.dy + 50 * math.sin(hourAngle),
      ),
      hourHandPaint,
    );

    // 중심점
    canvas.drawCircle(center, 6, Paint()..color = const Color(0xFFFFB8C6));
  }

  @override
  bool shouldRepaint(ClockPainter oldDelegate) => true;
}
