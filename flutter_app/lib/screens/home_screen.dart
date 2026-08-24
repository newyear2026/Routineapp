import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_route_observer.dart';
import '../application/routine_app_controller.dart';
import '../domain/models/routine.dart';
import '../l10n/app_localizations.dart';
import '../domain/utils/time_minutes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/ds.dart';
import '../widgets/home/circular_timetable_area.dart';

/// 홈에 그리는 '다음 일정' 최대 개수.
///
/// 헤더 개수 표기와 실제 타일 수가 어긋나지 않도록 한 곳에서만 정한다.
const int _maxUpcomingTiles = 3;

/// Figma Orbit 기준의 홈. 중복된 요약/관리 UI 대신 현재 흐름만 보여준다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() => context.read<RoutineAppController>().reloadOnReturn();

  /// 완료·나중에·스킵 실행 후 되돌리기 스낵바를 띄운다.
  Future<void> _runSlotAction(
    Future<RoutineActionUndo?> Function() action,
    String doneMessage,
  ) async {
    final controller = context.read<RoutineAppController>();
    final messenger = ScaffoldMessenger.of(context);
    final undo = await action();
    if (!mounted || undo == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(doneMessage),
          action: SnackBarAction(
            label: AppLocalizations.of(context).commonUndo,
            onPressed: () => controller.undoAction(undo),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoutineAppController>(
      builder: (context, app, _) {
        final l10n = AppLocalizations.of(context);
        if (!app.isLoaded) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.orbitPrimary),
            ),
          );
        }
        final home = app.homeSnapshotFor(l10n);
        // 다음 일정은 upcomingRoutines 하나만 소비한다.
        // nextAfterDisplay를 함께 넣으면 첫 항목이 중복된다.
        final upcoming = home.upcomingRoutines;

        return Scaffold(
          bottomNavigationBar: OrbitBottomNavigation(
            currentIndex: 0,
            onHome: () {},
            onProgress: () => context.go('/progress'),
            onRoutines: () => context.go('/routines'),
            onSettings: () => context.go('/settings'),
          ),
          body: AppScreenShell(
            child: SingleChildScrollView(
              // 탭 목적지 4개는 같은 상단 여백을 쓴다. 홈만 다르면
              // 탭을 옮길 때 제목이 그대로 튄다.
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(home.dateWithWeekdayLabel,
                                style: AppTextStyles.caption),
                            const SizedBox(height: 2),
                            Text(l10n.homeTitle,
                                style: AppTextStyles.titleScreen),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.commonSettings,
                        onPressed: () => context.go('/settings'),
                        icon: const Icon(Icons.settings_outlined),
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _FocusStrip(
                    routine: home.displayRoutine,
                    isUpcoming: home.isDisplayUpcoming,
                    timingHint: home.currentRoutineCard?.timingHint,
                    onTap: home.displayRoutine == null
                        ? () => context.push('/routine-add')
                        : () => context.push(
                              '/routine-add?id=${home.displayRoutine!.id}',
                            ),
                  ),
                  const SizedBox(height: 12),
                  if (home.segments.isEmpty)
                    const _EmptyOrbit()
                  else
                    Center(
                      child: CircularTimetableArea(
                        routines: home.segments,
                        currentTime: home.clockTime,
                        activeRoutine: home.activeRoutineForRing,
                        size: 286,
                      ),
                    ),
                  const SizedBox(height: 18),
                  _SlotActionBar(
                    enabled: home.canActOnCurrentSlot,
                    completeLabel: home.completeButtonLabel,
                    disabledMessage: home.actionDisabledMessage,
                    onComplete: () => _runSlotAction(
                      app.completeCurrent,
                      l10n.homeMarkedDone,
                    ),
                    onSnooze: () => _runSlotAction(
                      app.snoozeCurrent,
                      l10n.homeMarkedSnoozed,
                    ),
                    onSkip: () => _runSlotAction(
                      app.skipCurrent,
                      l10n.homeMarkedSkipped,
                    ),
                  ),
                  // 오늘 루틴이 하나도 없으면 여기가 유일한 다음 행동이다.
                  // 홈에는 FAB이 없으므로 화면 안에 경로를 둔다.
                  if (home.isEmptyDay) ...[
                    const SizedBox(height: 10),
                    AppButton(
                      key: const Key('home-add-routine-button'),
                      label: l10n.homeAddRoutine,
                      icon: Icons.add_rounded,
                      variant: AppButtonVariant.secondary,
                      height: 46,
                      onPressed: () => context.push('/routine-add'),
                    ),
                  ],
                  // 구분선은 1.22:1로 배경에 묻힌다. 여백으로 나눈다.
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      // 제목이 먼저 줄고 개수는 남긴다.
                      Flexible(
                        child: Text(
                          l10n.homeUpcomingSection,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSection,
                        ),
                      ),
                      const Spacer(),
                      // 목록은 최대 [_maxUpcomingTiles]개만 그린다.
                      // 전체 개수만 적으면 화면에 보이는 수와 어긋난다.
                      Text(
                        upcoming.length > _maxUpcomingTiles
                            ? '$_maxUpcomingTiles / ${upcoming.length}'
                            : l10n.routineCount(upcoming.length),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (upcoming.isEmpty)
                    // 빈 하루의 '무엇을 할지'는 위 액션 영역이 버튼과 함께 말한다.
                    // 여기서 또 안내하면 한 화면에서 같은 말을 세 번 하게 된다.
                    Text(
                      l10n.homeNoRoutinesLeft,
                      style: AppTextStyles.caption,
                    )
                  else
                    ...upcoming.take(_maxUpcomingTiles).map(
                          (routine) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppRoutineRow(
                              color: routine.color,
                              title: routine.title,
                              subtitle: _timeRange(routine),
                              onTap: () => context.push(
                                '/routine-add?id=${routine.id}',
                              ),
                            ),
                          ),
                        ),
                  if (upcoming.length > _maxUpcomingTiles)
                    _MoreUpcomingLink(
                      remaining: upcoming.length - _maxUpcomingTiles,
                      onTap: () => context.go('/routines'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 화면에서 가장 먼저 읽혀야 하는 줄 — 지금(NOW) 또는 다음(NEXT) 루틴.
class _FocusStrip extends StatelessWidget {
  const _FocusStrip({
    required this.routine,
    required this.isUpcoming,
    required this.timingHint,
    required this.onTap,
  });

  final Routine? routine;
  final bool isUpcoming;
  final String? timingHint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final routine = this.routine;
    // 진행 중인 루틴이 없을 때 다가오는 루틴을 NOW로 부르면 사실과 달라진다.
    final badge = routine == null
        ? l10n.commonToday
        : isUpcoming
            ? l10n.homeBadgeNext
            : l10n.homeBadgeNow;
    final name = routine?.title ?? l10n.homeCreateFirstRoutine;
    final time = routine == null ? l10n.homeStartYourDay : _timeRange(routine);

    return Material(
      color: AppColors.orbitSurface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: appSurfaceDecoration(radius: 24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.orbitPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSection,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 시각과 남은 시간은 언어마다 길이가 크게 달라진다.
              // 폭을 나눠 갖게 하고, 넘치면 오른쪽 열이 줄바꿈하도록 둔다.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 132),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                    if (timingHint != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        timingHint!,
                        maxLines: 2,
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionTight.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 완료 / 나중에 / 스킵 — MVP 핵심 액션.
///
/// 누를 수 없을 때는 버튼을 숨기지 않고 이유를 함께 보여준다 (UI_STANDARDS 4).
class _SlotActionBar extends StatelessWidget {
  const _SlotActionBar({
    required this.enabled,
    required this.completeLabel,
    required this.disabledMessage,
    required this.onComplete,
    required this.onSnooze,
    required this.onSkip,
  });

  final bool enabled;
  final String completeLabel;
  final String? disabledMessage;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          key: const Key('home-complete-button'),
          label: completeLabel,
          icon: Icons.check_rounded,
          onPressed: enabled ? onComplete : null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AppButton(
                key: const Key('home-snooze-button'),
                label: l10n.statusSnoozed,
                variant: AppButtonVariant.secondary,
                height: 46,
                onPressed: enabled ? onSnooze : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                key: const Key('home-skip-button'),
                label: l10n.statusSkipped,
                variant: AppButtonVariant.ghost,
                height: 46,
                onPressed: enabled ? onSkip : null,
              ),
            ),
          ],
        ),
        if (!enabled && disabledMessage != null) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              disabledMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ],
    );
  }
}

/// 잘려나간 나머지 일정으로 가는 경로.
///
/// 헤더가 '3 / 5'라고 말한 뒤 나머지 2개를 볼 방법이 없으면 안 된다.
class _MoreUpcomingLink extends StatelessWidget {
  const _MoreUpcomingLink({required this.remaining, required this.onTap});

  final int remaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.center,
        child: TextButton(
          key: const Key('home-more-upcoming-link'),
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.orbitPrimary,
            minimumSize: const Size(0, 44),
          ),
          child: Text(
            AppLocalizations.of(context).homeSeeRemaining(remaining),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.orbitPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
}

class _EmptyOrbit extends StatelessWidget {
  const _EmptyOrbit();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 286,
          height: 286,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.orbitHalo, width: 9),
          ),
          child: Text(AppLocalizations.of(context).homeEmptyRingTitle,
              textAlign: TextAlign.center, style: AppTextStyles.body),
        ),
      );
}

String _timeRange(Routine routine) => TimeMinutes.formatRange(
      routine.startMinutesFromMidnight,
      routine.endMinutesFromMidnight,
    );
