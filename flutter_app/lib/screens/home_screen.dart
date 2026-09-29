import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_optional_provider.dart';
import '../app_route_observer.dart';
import '../application/home/home_focus_state.dart';
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
import '../widgets/home/home_focus_card.dart';
import '../widgets/home/home_timetable_scene.dart';
import '../widgets/release/release_announcement.dart';
import '../widgets/store/launch_gift_dialog.dart';
import '../data/store/character_pack_catalog.dart';
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
  bool _launchGiftScheduled = false;

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
    _scheduleLaunchGift();
  }

  void _onAnnouncementsChanged() {
    if (!mounted) return;
    setState(() {});
    _scheduleAnnouncement();
    _scheduleLaunchGift();
  }

  void _scheduleLaunchGift() {
    if (_launchGiftScheduled || !mounted) return;
    final app = context.read<RoutineAppController>();
    if (!app.shouldShowLaunchGift) return;
    _launchGiftScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _launchGiftScheduled = false;
      if (!mounted ||
          !app.shouldShowLaunchGift ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      try {
        await app.markLaunchGiftSeen();
      } catch (e) {
        debugPrint('launch gift acknowledgement failed: $e');
        return;
      }
      if (!mounted) return;
      final useNow = await showLaunchGiftDialog(context);
      if (!mounted) return;
      if (useNow) {
        await app.selectCharacterPack(CharacterPackCatalog.stargazerCat);
      }
      _scheduleAnnouncement();
      _scheduleUpdatePrompt();
    });
  }

  /// 방금 설치한 업데이트가 무엇을 바꿨는지 말한다.
  ///
  /// 업데이트 안내보다 앞에 선다 — 이쪽은 손에 든 빌드 이야기이고, 그쪽은
  /// 내일도 기다려 준다.
  void _scheduleAnnouncement() {
    final announcements = _announcements;
    if (_announcementScheduled ||
        announcements == null ||
        context.read<RoutineAppController>().shouldShowLaunchGift ||
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
        context.read<RoutineAppController>().shouldShowLaunchGift ||
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
  void didPopNext() {
    context.read<RoutineAppController>().reloadOnReturn();
    _scheduleLaunchGift();
  }

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
        _scheduleLaunchGift();
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
                  HomeFocusCard(
                    home: home,
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
                      timetableBuilder: (size) => CircularTimetableArea(
                          routines: home.segments,
                          currentTime: home.clockTime,
                          activeRoutine: home.activeRoutineForRing,
                          showNowLabel: false,
                          size: size),
                    ),
                  // 누를 수 있을 때만 버튼을 둔다. 예정·완료·건너뜀에서 흐린
                  // 버튼을 남기면 아직 시작도 안 한 루틴에 «완료»가 떠 있게 된다.
                  if (home.focusState.showsSlotActions) ...[
                    const SizedBox(height: 12),
                    _SlotActionBar(
                      enabled: home.canActOnCurrentSlot,
                      completeLabel: home.completeButtonLabel,
                      showSnooze: home.focusState == HomeFocusState.active,
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
                  ],
                  // 오늘 루틴이 하나도 없으면 여기가 유일한 다음 행동이다.
                  // 홈에는 FAB이 없으므로 화면 안에 경로를 둔다.
                  if (home.isEmptyDay) ...[
                    const SizedBox(height: 18),
                    AppButton(
                      key: const Key('home-add-routine-button'),
                      label: l10n.homeAddRoutine,
                      icon: Icons.add_rounded,
                      onPressed: () => context.push('/routine-add'),
                    ),
                  ],
                  // 구분선은 1.22:1로 배경에 묻힌다. 여백으로 나눈다.
                  const SizedBox(height: 32),
                  Text(
                    l10n.homeUpcomingSection,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSection,
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

/// 완료 / 나중에 / 건너뛰기 — MVP 핵심 액션.
///
/// 진행 중·미룸 카드에서만 보인다 ([HomeFocusState.showsSlotActions]).
/// 이미 미룬 루틴은 «나중에»를 다시 내밀지 않는다.
class _SlotActionBar extends StatelessWidget {
  const _SlotActionBar({
    required this.enabled,
    required this.completeLabel,
    required this.showSnooze,
    required this.onComplete,
    required this.onSnooze,
    required this.onSkip,
  });

  final bool enabled;
  final String completeLabel;
  final bool showSnooze;
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
            if (showSnooze) ...[
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
            ],
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
