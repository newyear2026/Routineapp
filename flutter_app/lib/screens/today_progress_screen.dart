import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../application/mappers/progress_view_mapper.dart';
import '../application/routine_app_controller.dart';
import '../domain/progress/daily_progress.dart';
import '../theme/home_theme.dart';
import '../widgets/home/home_decorative_background.dart';
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
        final feedback = ProgressViewMapper.feedbackForPercent(progress.percent);
        final miniStats = ProgressViewMapper.miniStatsFromProgress(
          completed: progress.completed,
          total: progress.total,
        );

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(gradient: HomeTheme.pageGradient),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: HomeTheme.mobileWidth),
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ProgressAppBar(
                              dateLine: '$dateString $dayOfWeekLabel',
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
                                padding:
                                    const EdgeInsets.fromLTRB(20, 4, 20, 28),
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
                                      Text(
                                        '오늘 예정된 루틴이 없어요.\n루틴을 추가해 보세요.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.45,
                                          color: HomeTheme.textMuted
                                              .withValues(alpha: 0.92),
                                        ),
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 22),
                                      const Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding:
                                              EdgeInsets.only(left: 4, bottom: 10),
                                          child: Text(
                                            '상태별 루틴',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: HomeTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      ...statusGroups.map(
                                        (g) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressAppBar extends StatelessWidget {
  const _ProgressAppBar({
    required this.dateLine,
    required this.onBack,
  });

  final String dateLine;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 6),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: HomeTheme.textMuted.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: HomeTheme.textPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  '오늘의 루틴',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: HomeTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLine,
                  style: TextStyle(
                    fontSize: 11,
                    color: HomeTheme.textMuted.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
