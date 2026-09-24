import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_optional_provider.dart';
import '../app_route_observer.dart';
import '../application/release/release_announcements.dart';
import '../application/review/review_prompt.dart';
import '../application/routine_app_controller.dart';
import '../application/update/app_updates_controller.dart';
import '../domain/models/routine.dart';
import '../l10n/app_localizations.dart';
import '../widgets/routine_load_failure_view.dart';
import '../domain/utils/time_minutes.dart';
import '../theme/app_colors.dart';
import '../widgets/ads/home_upcoming_ad_card.dart';
import '../widgets/ds/app_pixel_hint.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/ds.dart';
import '../widgets/home/circular_timetable_area.dart';
import '../widgets/home/home_timetable_scene.dart';
import '../widgets/release/release_announcement.dart';
import '../widgets/update/update_banner.dart';
import '../widgets/update/update_prompt.dart';

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
  AppUpdates? _updates;
  ReleaseAnnouncements? _announcements;
  ReviewPrompt? _reviewPrompt;
  bool _updatePromptScheduled = false;
  bool _announcementScheduled = false;

  /// 돌고 있는 빌드를 읽는 일이 끝났는지. 업데이트 다이얼로그가 «현재 버전»
  /// 행을 그리기 전에 이것을 기다린다.
  Future<void>? _announcementsReady;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) appRouteObserver.subscribe(this, route);

    // 확인을 여기서 시작하는 이유는 홈이 앱의 유일한 착륙 지점이기 때문이다.
    // 앱 최상단에서 걸면 스플래시·온보딩을 지나는 동안 이미 물어보게 된다.
    // 두 번 불러도 값은 들지 않는다 — 컨트롤러가 같은 날 두 번째 확인을 버리고,
    // [ReleaseAnnouncements.start]는 첫 번만 일한다.
    // 프로바이더가 없으면 null이다 — 이 화면만 띄운 테스트·미리보기다. 그때는
    // 배너도 다이얼로그도 없고, 그것이 Play 서비스가 없는 기기가 받는 앱과
    // 같은 모습이다.
    final nextUpdates = context.maybeRead<AppUpdates>();
    if (nextUpdates != null && !identical(_updates, nextUpdates)) {
      _updates?.removeListener(_onUpdatesChanged);
      _updates = nextUpdates..addListener(_onUpdatesChanged);
      unawaited(nextUpdates.refresh());
    }
    _reviewPrompt = context.maybeRead<ReviewPrompt>();
    final nextAnnouncements = context.maybeRead<ReleaseAnnouncements>();
    if (nextAnnouncements != null &&
        !identical(_announcements, nextAnnouncements)) {
      _announcements?.removeListener(_onAnnouncementsChanged);
      _announcements = nextAnnouncements..addListener(_onAnnouncementsChanged);
      _announcementsReady = nextAnnouncements.start();
      unawaited(_announcementsReady!);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _updates?.removeListener(_onUpdatesChanged);
    _announcements?.removeListener(_onAnnouncementsChanged);
    super.dispose();
  }

  void _onUpdatesChanged() {
    if (!mounted) return;
    setState(() {});
    _scheduleUpdatePrompt();
  }

  void _onAnnouncementsChanged() {
    if (!mounted) return;
    setState(() {});
    _scheduleAnnouncement();
  }

  /// 방금 설치한 업데이트가 무엇을 바꿨는지 말한다.
  ///
  /// 업데이트 안내보다 앞에 선다 — 이쪽은 손에 든 빌드 이야기이고, 그쪽은
  /// 내일도 기다려 준다.
  void _scheduleAnnouncement() {
    final announcements = _announcements;
    if (_announcementScheduled ||
        announcements == null ||
        !announcements.shouldAnnounce) {
      return;
    }
    _announcementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _announcementScheduled = false;
      if (!mounted || !announcements.shouldAnnounce) return;
      final wantsMore = await showReleaseAnnouncement(
        context,
        announcements: announcements,
      );
      if (!wantsMore || !mounted) return;
      context.push('/release-notes');
    });
  }

  /// 프레임이 끝나고, 더 앞선 것이 줄 서 있지 않을 때 업데이트를 권한다.
  ///
  /// 릴리스 카드 뒤다. 다이얼로그를 쌓으면 먼저 뜬 쪽이 묻힌다.
  void _scheduleUpdatePrompt() {
    final updates = _updates;
    if (_updatePromptScheduled ||
        updates == null ||
        !updates.shouldPrompt ||
        (_announcements?.shouldAnnounce ?? false)) {
      return;
    }
    _updatePromptScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _updatePromptScheduled = false;
      // 버전 행은 잠깐 기다릴 값이 있다. Play 왕복이 패키지 정보 읽기보다 훨씬
      // 느려 보통은 공짜지만, 이게 없으면 어느 future가 이겼는지에 따라 행이
      // 있기도 없기도 하다. 실행마다 한 줄씩 키가 다른 다이얼로그는 읽는
      // 사람에게 버그로 보인다.
      await _announcementsReady;
      if (!mounted || !updates.shouldPrompt) return;
      await showUpdatePrompt(
        context,
        updates: updates,
        currentVersion: _announcements?.version?.version,
      );
    });
  }

  Future<void> _openStoreFromBanner() async {
    final updates = _updates;
    if (updates == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final failureMessage = AppLocalizations.of(context).updateStoreFailed;
    if (await updates.openStore()) return;
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failureMessage)));
  }

  @override
  void didPopNext() => context.read<RoutineAppController>().reloadOnReturn();

  /// 완료·나중에·스킵 실행 후 되돌리기 스낵바를 띄운다.
  ///
  /// [afterApplied]는 기록이 저장된 뒤에만 부른다 — 실패한 완료에 리뷰를
  /// 묻지 않는다.
  Future<void> _runSlotAction(
    Future<RoutineActionUndo?> Function() action,
    String doneMessage, {
    VoidCallback? afterApplied,
  }) async {
    final controller = context.read<RoutineAppController>();
    final RoutineActionUndo? undo;
    try {
      undo = await action();
    } catch (_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).homeActionSaveFailed,
            ),
          ),
        );
      return;
    }
    if (!mounted || undo == null) return;
    final appliedUndo = undo;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(doneMessage),
          action: SnackBarAction(
            label: AppLocalizations.of(context).commonUndo,
            onPressed: () async {
              try {
                await controller.undoAction(appliedUndo);
              } catch (_) {
                if (!mounted) return;
                final failureMessenger = ScaffoldMessenger.of(context);
                failureMessenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context).homeActionUndoFailed,
                      ),
                    ),
                  );
              }
            },
          ),
        ),
      );
    afterApplied?.call();
  }

  /// 완료 스낵바를 한 박자 읽을 틈을 둔 뒤 리뷰 창을 청한다.
  /// 띄울지 말지는 [ReviewPrompt]가 정한다.
  void _askForReviewAfterComplete() {
    final reviewPrompt = _reviewPrompt;
    if (reviewPrompt == null) return;
    unawaited(
        Future<void>.delayed(const Duration(milliseconds: 1200), () async {
      if (!mounted) return;
      await reviewPrompt.onRoutineCompleted();
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoutineAppController>(
      builder: (context, app, _) {
        final l10n = AppLocalizations.of(context);
        if (app.hasBlockingLoadError) {
          return const Scaffold(body: RoutineLoadFailureView());
        }
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
                  // 날짜·제목 위다. 아래에 두면 «오늘의 리듬»과 포커스 카드
                  // 사이를 갈라놓는다.
                  if (_updates?.showBanner ?? false) ...[
                    UpdateBanner(
                      onUpdate: _openStoreFromBanner,
                      onDismiss: () => _updates?.hideBanner(),
                    ),
                    const SizedBox(height: 16),
                  ],
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
                        icon: const AppIcon(Icons.settings_outlined),
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
                    HomeTimetableScene(
                      catPose: homeCatPose(home),
                      timetableBuilder: (size) => CircularTimetableArea(
                          routines: home.segments,
                          currentTime: home.clockTime,
                          activeRoutine: home.activeRoutineForRing,
                          showNowLabel: false,
                          size: size),
                    ),
                  const SizedBox(height: 18),
                  _SlotActionBar(
                    enabled: home.canActOnCurrentSlot,
                    completeLabel: home.completeButtonLabel,
                    disabledMessage: home.actionDisabledMessage,
                    onComplete: () => _runSlotAction(
                      app.completeCurrent,
                      l10n.homeMarkedDone,
                      afterApplied: _askForReviewAfterComplete,
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
                              icon: routine.iconId,
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
                  // Slot A — 섹션의 맨 끝이다. «더 보기» 링크보다 뒤에 두어
                  // 목록과 그 목록의 링크를 광고가 갈라놓지 않게 한다.
                  // 띄울 수 없으면 높이 0이라 레이아웃은 그대로다.
                  HomeUpcomingAdCard(
                    // «더 보기» 링크가 나타났다 사라지면 이 위젯의 형제
                    // 순번이 바뀐다. 키가 없으면 그때 State가 새로 만들어져
                    // 같은 세션에 광고를 다시 불러오게 된다.
                    key: const ValueKey('home-upcoming-ad'),
                    upcomingCount: upcoming.length,
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
            ? l10n.statusUpcoming
            : l10n.statusInProgress;
    final name = routine?.title ?? l10n.homeCreateFirstRoutine;
    final time = routine == null ? l10n.homeStartYourDay : _timeRange(routine);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: appSurfaceDecoration(radius: 24),
          child: Row(
            children: [
              if (routine != null) ...[
                RoutineMark(
                  icon: routine.iconId,
                  color: routine.color,
                  size: 40,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppStatusBadge(
                      label: badge,
                      tone: isUpcoming
                          ? AppStatusBadgeTone.neutral
                          : AppStatusBadgeTone.info,
                    ),
                    const SizedBox(height: 6),
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
                label: l10n.actionSkip,
                variant: AppButtonVariant.secondary,
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: AppPixelHint(
            message: AppLocalizations.of(context).homeEmptyRingTitle),
      );
}

String _timeRange(Routine routine) => TimeMinutes.formatRange(
      routine.startMinutesFromMidnight,
      routine.endMinutesFromMidnight,
    );
