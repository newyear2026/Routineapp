import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

class TodayProgressScreen extends StatelessWidget {
  const TodayProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = '${now.month}월 ${now.day}일';
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final dayOfWeek = weekdays[now.weekday % 7];

    const completedCount = 4;
    const laterCount = 1;
    const skippedCount = 1;
    const pendingCount = 2;
    const totalCount = 8;
    const progressPercent = 50;

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
            // 배경 데코
            ..._buildFloatingDecorations(),

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
                        Column(
                          children: [
                            const Text(
                              '오늘의 루틴',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF8B7B9E),
                              ),
                            ),
                            Text(
                              '$dateString $dayOfWeek요일',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFB8A4C9),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),

                  // 내용
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // 큰 진행률 카드
                          _buildProgressCard(progressPercent, completedCount,
                              totalCount, laterCount + pendingCount),
                          const SizedBox(height: 24),

                          // 상태별 루틴
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 12),
                              child: Text(
                                '상태별 루틴',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8B7B9E),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          _buildStatusSection(
                            '완료',
                            Icons.check_circle,
                            const Color(0xFFD4E4FF),
                            const Color(0xFF6B8BC9),
                            completedCount,
                            [
                              {'emoji': '🌅', 'name': '기상', 'time': '07:00'},
                              {'emoji': '💪', 'name': '운동', 'time': '07:30'},
                              {'emoji': '🍳', 'name': '아침식사', 'time': '09:00'},
                              {'emoji': '🍱', 'name': '점심식사', 'time': '12:00'},
                            ],
                          ),
                          const SizedBox(height: 12),

                          _buildStatusSection(
                            '나중에',
                            Icons.access_time,
                            const Color(0xFFFFE9D4),
                            const Color(0xFFD9A57B),
                            laterCount,
                            [
                              {'emoji': '📚', 'name': '공부', 'time': '14:00'},
                            ],
                          ),
                          const SizedBox(height: 12),

                          _buildStatusSection(
                            '스킵',
                            Icons.skip_next,
                            const Color(0xFFFFE4E9),
                            const Color(0xFFD99BB0),
                            skippedCount,
                            [
                              {'emoji': '🌙', 'name': '취침', 'time': '23:00'},
                            ],
                          ),
                          const SizedBox(height: 12),

                          _buildStatusSection(
                            '대기',
                            Icons.circle_outlined,
                            const Color(0xFFF5F0FF),
                            const Color(0xFFB8A4C9),
                            pendingCount,
                            [
                              {'emoji': '☕', 'name': '휴식', 'time': '15:00'},
                              {'emoji': '🍽️', 'name': '저녁식사', 'time': '18:00'},
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 캐릭터 피드백
                          _buildEncouragementCard(),
                          const SizedBox(height: 24),

                          // 추가 통계
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard('🔥', '연속 달성', '3일'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard('⭐', '평균 달성률', '67%'),
                              ),
                            ],
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

  Widget _buildProgressCard(
    int percent,
    int completed,
    int total,
    int remaining,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFFFF9F5)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB8A4C9).withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE8DDFA).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // 원형 프로그레스
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 12,
                    backgroundColor:
                        const Color(0xFFB8A4C9).withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation(
                      Color(0xFFFFB8C6),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B7B9E),
                      ),
                    ),
                    const Text(
                      '완료',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB8A4C9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 통계
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniStat('완료', completed, const Color(0xFF6B8BC9)),
              _buildMiniStat('남은 루틴', remaining, const Color(0xFFD9A57B)),
              _buildMiniStat('전체', total, const Color(0xFF8B7B9E)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFFB8A4C9),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(
    String label,
    IconData icon,
    Color bgColor,
    Color textColor,
    int count,
    List<Map<String, String>> routines,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count개',
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: routines
                .map((r) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            r['emoji']!,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            r['name']!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8B7B9E),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            r['time']!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFB8A4C9),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEncouragementCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFF4EB).withOpacity(0.6),
            const Color(0xFFFFEFF5).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFFFB8C6).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
            child: const Center(
              child: Text('🐻', style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('💪', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text(
                      '오늘 하루 피드백',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8B7B9E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '잘하고 있어요!\n벌써 절반이나 했어요!',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF8B7B9E),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '이 기세로 계속 가봐요',
                  style: TextStyle(
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

  Widget _buildStatCard(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8DDFA).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFB8A4C9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF8B7B9E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static List<Widget> _buildFloatingDecorations() {
    final decorations = <Widget>[];
    final random = math.Random();

    for (int i = 0; i < 8; i++) {
      decorations.add(
        Positioned(
          left: random.nextDouble() * 400,
          top: random.nextDouble() * 800,
          child: Text(
            '✨',
            style: TextStyle(
              fontSize: 12 + random.nextDouble() * 8,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ),
      );
    }

    return decorations;
  }
}
