import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InitialRoutineSetupScreen extends StatefulWidget {
  const InitialRoutineSetupScreen({super.key});

  @override
  State<InitialRoutineSetupScreen> createState() =>
      _InitialRoutineSetupScreenState();
}

class _InitialRoutineSetupScreenState extends State<InitialRoutineSetupScreen> {
  final List<RoutineTemplate> _templates = [
    RoutineTemplate(
      emoji: '🌅',
      name: '기상',
      time: '07:00',
      color: const Color(0xFFFFE4E9),
      isSelected: true,
    ),
    RoutineTemplate(
      emoji: '💪',
      name: '운동',
      time: '07:30',
      color: const Color(0xFFFFD4E0),
      isSelected: true,
    ),
    RoutineTemplate(
      emoji: '🍳',
      name: '아침식사',
      time: '09:00',
      color: const Color(0xFFFFE9D4),
      isSelected: true,
    ),
    RoutineTemplate(
      emoji: '📚',
      name: '공부',
      time: '10:00',
      color: const Color(0xFFE8DDFA),
      isSelected: false,
    ),
    RoutineTemplate(
      emoji: '🍱',
      name: '점심식사',
      time: '12:00',
      color: const Color(0xFFFFFDDC5),
      isSelected: true,
    ),
    RoutineTemplate(
      emoji: '☕',
      name: '휴식',
      time: '15:00',
      color: const Color(0xFFD4E4FF),
      isSelected: false,
    ),
    RoutineTemplate(
      emoji: '🍽️',
      name: '저녁식사',
      time: '18:00',
      color: const Color(0xFFFFE4E9),
      isSelected: true,
    ),
    RoutineTemplate(
      emoji: '🌙',
      name: '취침',
      time: '23:00',
      color: const Color(0xFFD4C5F0),
      isSelected: true,
    ),
  ];

  void _toggleRoutine(int index) {
    setState(() {
      _templates[index].isSelected = !_templates[index].isSelected;
    });
  }

  void _completeSetup() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _templates.where((t) => t.isSelected).length;

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
          child: Column(
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const Text(
                      '루틴 선택',
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFF8B7B9E),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      '하루를 시작해볼까요?',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B7B9E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '원하는 루틴을 선택해주세요\n나중에 언제든 수정할 수 있어요',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB8A4C9),
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    
                    // 선택된 루틴 수
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8DDFA).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$selectedCount개 선택됨',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8B7B9E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 루틴 목록
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    return _buildRoutineCard(_templates[index], index);
                  },
                ),
              ),

              // 완료 버튼
              Padding(
                padding: const EdgeInsets.all(30),
                child: GestureDetector(
                  onTap: _completeSetup,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4C5F0), Color(0xFFC4B5E6)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4C5F0).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '완료하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutineCard(RoutineTemplate template, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _toggleRoutine(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: template.isSelected
                ? Colors.white.withOpacity(0.9)
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: template.isSelected
                  ? template.color
                  : const Color(0xFFE8DDFA).withOpacity(0.3),
              width: template.isSelected ? 2 : 1,
            ),
            boxShadow: template.isSelected
                ? [
                    BoxShadow(
                      color: template.color.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              // 체크박스
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: template.isSelected
                      ? template.color
                      : Colors.transparent,
                  border: Border.all(
                    color: template.isSelected
                        ? template.color
                        : const Color(0xFFB8A4C9).withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: template.isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // 이모지 아이콘
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      template.color,
                      template.color.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    template.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 루틴 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B7B9E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.time,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFB8A4C9),
                      ),
                    ),
                  ],
                ),
              ),

              // 추천 뱃지
              if (index < 3)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB8C6).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '추천',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFFFB8C6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoutineTemplate {
  final String emoji;
  final String name;
  final String time;
  final Color color;
  bool isSelected;

  RoutineTemplate({
    required this.emoji,
    required this.name,
    required this.time,
    required this.color,
    this.isSelected = false,
  });
}
