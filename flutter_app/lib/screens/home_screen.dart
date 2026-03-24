import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/home_dummy.dart';
import '../theme/home_theme.dart';
import '../widgets/home/circular_timetable_area.dart';
import '../widgets/home/current_routine_card.dart';
import '../widgets/home/home_bottom_actions.dart';
import '../widgets/home/home_character_section.dart';
import '../widgets/home/home_decorative_background.dart';
import '../widgets/home/home_header_bar.dart';

String _greetingForHour(int hour) {
  if (hour < 12) return '좋은 아침이에요';
  if (hour < 18) return '좋은 오후예요';
  return '좋은 저녁이에요';
}

/// Home — 모바일 프레임 + 분리 위젯 + 더미 데이터 (상태 연결은 콜백/Provider로 확장)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = '${now.month}월 ${now.day}일';
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final dayOfWeekLabel = '${weekdays[now.weekday - 1]}요일';
    final greeting = _greetingForHour(homeDummyClockHour);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab_routine_add',
        onPressed: () => context.push('/routine-add'),
        backgroundColor: Colors.white.withValues(alpha: 0.94),
        elevation: 3,
        child: const Icon(
          Icons.add_rounded,
          color: HomeTheme.textPrimary,
          size: 28,
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: HomeTheme.pageGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: HomeTheme.mobileWidth),
              child: Container(
                margin: const EdgeInsets.all(16),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(HomeTheme.shellRadius),
                  gradient: HomeTheme.shellGradient,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    const Positioned.fill(child: HomeDecorativeBackground()),
                    Column(
                      children: [
                        HomeHeaderBar(
                          dateString: dateString,
                          dayOfWeekLabel: dayOfWeekLabel,
                          greeting: greeting,
                          progress: homeDummyProgress,
                          onProgressTap: () => context.go('/progress'),
                          onSettingsTap: () => context.go('/settings'),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            child: Column(
                              children: [
                                const HomeCharacterSection(character: homeDummyCharacter),
                                const SizedBox(height: 24),
                                CircularTimetableArea(
                                  routines: homeDummySegments,
                                  currentTime: const TimeOfDay(
                                    hour: homeDummyClockHour,
                                    minute: homeDummyClockMinute,
                                  ),
                                  activeRoutine: homeDummyCurrentRoutine,
                                ),
                                const SizedBox(height: 20),
                                const CurrentRoutineCard(
                                  routine: homeDummyCurrentRoutine,
                                  next: homeDummyNextRoutine,
                                ),
                                const SizedBox(height: 16),
                                HomeBottomActions(
                                  completeLabel: '${homeDummyCurrentRoutine.name} 완료하기',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
