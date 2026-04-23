import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_route_observer.dart';
import '../application/home/home_snapshot.dart';
import '../application/routine_app_controller.dart';
import '../domain/models/routine.dart';
import '../theme/home_theme.dart';
import '../theme/app_theme_preset.dart';
import '../widgets/home/current_routine_card.dart';
import '../widgets/home/home_bottom_actions.dart';
import '../widgets/home/home_daily_summary_section.dart';
import '../widgets/home/home_header_bar.dart';
import '../widgets/home/home_now_focus_banner.dart';
import '../widgets/home/home_routine_manager_section.dart';
import '../widgets/home/home_timeline_section.dart';
import '../widgets/ds/ds.dart';

/// Home — [RoutineAppController.homeSnapshot]만 소비. 저장소는 컨트롤러 경유.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  bool _actionInFlight = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// push 로 연 화면에서 pop 으로 돌아올 때 저장소 다시 읽기 (예: 루틴 추가)
  @override
  void didPopNext() {
    _reloadStorage();
  }

  void _reloadStorage() {
    if (!mounted) return;
    context.read<RoutineAppController>().reloadOnReturn();
  }

  Future<void> _confirmDeleteRoutine(RoutineAppController app, String routineId) async {
    Routine? routine;
    for (final item in app.routines) {
      if (item.id == routineId) {
        routine = item;
        break;
      }
    }
    if (routine == null || !mounted) return;
    final targetRoutine = routine;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('루틴 삭제'),
        content: Text(
          '"${targetRoutine.title}" 루틴을 삭제할까요?\n원형 시간표와 관련 기록에도 바로 반영됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    final result = await app.deleteRoutine(routineId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.ok ? '루틴을 삭제했어요' : (result.errorMessage ?? '삭제에 실패했어요.')),
      ),
    );
  }

  Future<void> _runHomeAction({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    if (_actionInFlight || !mounted) return;
    setState(() => _actionInFlight = true);
    await HapticFeedback.lightImpact();
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          duration: const Duration(milliseconds: 900),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _actionInFlight = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoutineAppController>(
      builder: (context, app, _) {
        if (!app.isLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final HomeSnapshot h = app.homeSnapshot;
        final theme = context.appTheme;
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            heroTag: 'home_fab_routine_add',
            onPressed: () => context.push('/routine-add'),
            backgroundColor: theme.textPrimary,
            elevation: 4,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add_rounded, size: 26),
          ),
          body: AppScreenShell(
            child: Column(
              children: [
                HomeHeaderBar(
                  dateString: h.dateLabel,
                  dayOfWeekLabel: h.dayOfWeekLabel,
                  greeting: h.greeting,
                  progress: h.homeProgress,
                  onProgressTap: () => context.go('/progress'),
                  onSettingsTap: () => context.go('/settings'),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HomeNowFocusBanner(
                          routineName:
                              h.currentRoutineCard?.name ??
                              h.displayRoutine?.title ??
                              '오늘 루틴',
                          timingHint:
                              h.currentRoutineCard?.timingHint ??
                              h.currentRoutineStatusLabel ??
                              '오늘의 흐름을 확인해보세요',
                          progress: h.homeProgress,
                          nextRoutine: h.nextRoutineCard,
                          isUpcoming: h.isDisplayUpcoming,
                          compact: true,
                        ),
                        const SizedBox(height: 16),
                        AppSectionHeader(
                          eyebrow: 'CURRENT BLOCK',
                          title: h.isDisplayUpcoming ? '다음 루틴' : '현재 루틴',
                          subtitle: h.isDisplayUpcoming
                              ? '곧 시작할 루틴을 먼저 확인해두세요'
                              : '지금 처리해야 할 루틴부터 빠르게 끝내세요',
                        ),
                        const SizedBox(height: 10),
                        if (h.currentRoutineCard != null)
                          CurrentRoutineCard(
                            routine: h.currentRoutineCard!,
                            next: h.nextRoutineCard,
                            isUpcoming: h.isDisplayUpcoming,
                            onEdit: h.displayRoutine == null
                                ? null
                                : () => context.push('/routine-add?id=${h.displayRoutine!.id}'),
                          )
                        else
                          const _EmptyRoutineCard(),
                        if (h.currentRoutineStatusLabel != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            h.currentRoutineStatusLabel!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted.withValues(alpha: 0.88),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        HomeBottomActions(
                          completeLabel: h.completeButtonLabel,
                          isProcessing: _actionInFlight,
                          primaryEnabled: h.canActOnCurrentSlot,
                          secondaryEnabled: h.canActOnCurrentSlot,
                          disabledReason: h.canActOnCurrentSlot
                              ? null
                              : h.actionDisabledMessage,
                          onComplete: h.canActOnCurrentSlot
                              ? () => _runHomeAction(
                                    action: app.completeCurrent,
                                    successMessage: '루틴을 완료했어요',
                                  )
                              : null,
                          onLater: h.canActOnCurrentSlot
                              ? () => _runHomeAction(
                                    action: app.snoozeCurrent,
                                    successMessage: '루틴을 잠시 미뤘어요',
                                  )
                              : null,
                          onSkip: h.canActOnCurrentSlot
                              ? () => _runHomeAction(
                                    action: app.skipCurrent,
                                    successMessage: '루틴을 건너뛰었어요',
                                  )
                              : null,
                        ),
                        const SizedBox(height: 24),
                        const AppSectionHeader(
                          eyebrow: 'TODAY ORBIT',
                          title: '오늘 흐름',
                          subtitle: '현재 블록과 다음 전환 시점을 더 또렷한 원형 뷰로 확인해보세요',
                        ),
                        const SizedBox(height: 10),
                        HomeTimelineSection(
                          segments: h.segments,
                          clockTime: h.clockTime,
                          centerRoutineName: h.centerRoutineName,
                          activeRoutineForRing: h.activeRoutineForRing,
                          isEmpty: h.isEmptyDay,
                          statusLabel: h.currentRoutineStatusLabel,
                          nextRoutine: h.nextRoutineCard,
                        ),
                        const SizedBox(height: 18),
                        HomeDailySummarySection(
                          progress: h.homeProgress,
                          statusLabel: h.currentRoutineStatusLabel,
                          nextRoutine: h.nextRoutineCard,
                          isUpcoming: h.isDisplayUpcoming,
                          isEmptyDay: h.isEmptyDay,
                        ),
                        const SizedBox(height: 18),
                        HomeRoutineManagerSection(
                          routines: app.routines,
                          onAdd: () => context.push('/routine-add'),
                          onEdit: (routine) =>
                              context.push('/routine-add?id=${routine.id}'),
                          onDelete: (routine) =>
                              _confirmDeleteRoutine(app, routine.id),
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
    );
  }
}

class _EmptyRoutineCard extends StatelessWidget {
  const _EmptyRoutineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: HomeTheme.accentPink.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        '표시할 루틴이 없습니다.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: HomeTheme.textMuted.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
