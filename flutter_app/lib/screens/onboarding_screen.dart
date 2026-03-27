import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/local/onboarding_local_storage.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      emoji: '⏰',
      title: '하루를 시각화하세요',
      description: '24시간 원형 시계로\n하루 루틴을 한눈에 확인해요',
      gradientColors: [Color(0xFFFFE4E9), Color(0xFFFFD4E0)],
    ),
    OnboardingPage(
      emoji: '🔔',
      title: '알림으로 리마인드',
      description: '시간마다 귀여운 알림으로\n루틴 실행을 도와드려요',
      gradientColors: [Color(0xFFE8DDFA), Color(0xFFD4C5F0)],
    ),
    OnboardingPage(
      emoji: '📊',
      title: '성장을 기록하세요',
      description: '매일의 달성률을 확인하고\n꾸준한 습관을 만들어가요',
      gradientColors: [Color(0xFFD4E4FF), Color(0xFFC5D5F0)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishIntro();
    }
  }

  Future<void> _finishIntro() async {
    await OnboardingLocalStorage.markIntroSeen();
    if (!mounted) return;
    context.go('/routine-setup');
  }

  void _skipOnboarding() {
    _finishIntro();
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
        child: SafeArea(
          child: Column(
            children: [
              // 상단 Skip 버튼
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 60),
                    Text(
                      'Routine Timer',
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFF8B7B9E).withValues(alpha: 0.6),
                      ),
                    ),
                    TextButton(
                      onPressed: _skipOnboarding,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Color(0xFFB8A4C9),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPageContent(_pages[index]);
                  },
                ),
              ),

              // 하단 영역
              Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    // 페이지 인디케이터
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => _buildDot(index),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 다음 버튼
                    GestureDetector(
                      onTapDown: (_) => setState(() {}),
                      onTapUp: (_) => setState(() {}),
                      onTapCancel: () => setState(() {}),
                      onTap: _nextPage,
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
                              color: const Color(0xFFD4C5F0)
                                  .withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _currentPage == _pages.length - 1 ? '시작하기' : '다음',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 이모지 아이콘
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: page.gradientColors,
              ),
              boxShadow: [
                BoxShadow(
                  color: page.gradientColors[0].withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                page.emoji,
                style: const TextStyle(fontSize: 70),
              ),
            ),
          ),
          const SizedBox(height: 50),

          // 제목
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B7B9E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // 설명
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFFB8A4C9),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFD4C5F0)
            : const Color(0xFFD4C5F0).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final String emoji;
  final String title;
  final String description;
  final List<Color> gradientColors;

  OnboardingPage({
    required this.emoji,
    required this.title,
    required this.description,
    required this.gradientColors,
  });
}
