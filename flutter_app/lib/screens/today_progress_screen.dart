import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../application/mappers/progress_view_mapper.dart';
import '../application/routine_app_controller.dart';
import '../domain/progress/daily_progress.dart';
import '../widgets/ds/ds.dart';
import '../widgets/progress/progress_character_feedback.dart';
import '../widgets/progress/progress_mini_stats_row.dart';
import '../widgets/progress/progress_percent_header.dart';
import '../widgets/progress/progress_status_section.dart';

/// 오늘의 진행 — [RoutineLog] + 오늘 스케줄 [Routine] 기준
class TodayProgressScreen extends StatelessWidget {
  const TodayProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoutineAppController>(
      builder: (context, app, _) {
        if (!app.isLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final now = DateTime.now();
        final dateString = '${now.month}월 ${now.day}일';
        const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
        final dayOfWeekLabel = '${weekdays[now.weekday - 1]}요일';

        final todayRoutines = app.todayScheduledRoutines;
        final logs = app.todayLogs;

        final progress = calculateProgress(todayRoutines, logs);
        final remaining = progress.remaining;
        final statusGroups = ProgressViewMapper.buildStatusGroups(
          todayRoutines: todayRoutines,
          logsToday: logs,
        );
        final feedback =
            ProgressViewMapper.feedbackForPercent(progress.percent);
        final miniStats = ProgressViewMapper.miniStatsFromProgress(
          completed: progress.completed,
          total: progress.total,
        );
        return Scaffold(
          body: AppScreenShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPageHeader(
                  title: '오늘의 진행',
                  subtitle: '$dateString $dayOfWeekLabel',
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ProgressPercentHeader(
                          percent: progress.percent,
                          completedCount: progress.completed,
                          remainingCount: remaining,
                          totalCount: progress.total,
                        ),
                        if (todayRoutines.isEmpty) ...[
                          const SizedBox(height: 28),
                          const AppSectionHeader(
                            eyebrow: 'EMPTY DAY',
                            title: '오늘 예정된 루틴이 없어요',
                            subtitle: '새 루틴을 추가하면 이 화면에서 진행 상태를 확인할 수 있어요.',
                            centered: true,
                          ),
                        ] else ...[
                          const SizedBox(height: 22),
                          const AppSectionHeader(
                            eyebrow: 'STATUS GROUPS',
                            title: '상태별 루틴',
                            subtitle: '완료, 진행 중, 남은 루틴을 한눈에 정리했습니다.',
                          ),
                          const SizedBox(height: 10),
                          ...statusGroups.map(
                            (g) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ProgressStatusSection(
                                group: g,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        ProgressFeedbackCard(content: feedback),
                        const SizedBox(height: 16),
                        ProgressMiniStatsRow(stats: miniStats),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
