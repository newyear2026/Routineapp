import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_route_observer.dart';
import '../application/home/home_snapshot.dart';
import '../application/routine_app_controller.dart';
import '../theme/home_theme.dart';
import '../widgets/home/current_routine_card.dart';
import '../widgets/home/home_bottom_actions.dart';
import '../widgets/home/home_character_section.dart';
import '../widgets/home/home_decorative_background.dart';
import '../widgets/home/home_header_bar.dart';
import '../widgets/home/home_now_focus_banner.dart';
import '../widgets/home/home_timeline_section.dart';

/// Home — [RoutineAppController.homeSnapshot]만 소비. 저장소는 컨트롤러 경유.
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RoutineAppController>().load();
    });
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

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            heroTag: 'home_fab_routine_add',
            onPressed: () => context.push('/routine-add'),
            backgroundColor: Colors.white.withValues(alpha: 0.92),
            elevation: 2,
            foregroundColor: HomeTheme.textMuted,
            child: const Icon(Icons.add_rounded, size: 26),
          ),
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
                      borderRadius:
                          BorderRadius.circular(HomeTheme.shellRadius),
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
                              dateString: h.dateLabel,
                              dayOfWeekLabel: h.dayOfWeekLabel,
                              greeting: h.greeting,
                              progress: h.homeProgress,
                              onProgressTap: () => context.go('/progress'),
                              onSettingsTap: () => context.go('/settings'),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                child: Column(
                                  children: [
                                    HomeNowFocusBanner(
                                      character: h.character,
                                    ),
                                    const SizedBox(height: 18),
                                    HomeTimelineSection(
                                      segments: h.segments,
                                      clockTime: h.clockTime,
                                      centerRoutineName: h.centerRoutineName,
                                      activeRoutineForRing:
                                          h.activeRoutineForRing,
                                      isEmpty: h.isEmptyDay,
                                    ),
                                    if (h.currentRoutineStatusLabel != null) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        h.currentRoutineStatusLabel!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: HomeTheme.textMuted
                                              .withValues(alpha: 0.88),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 20),
                                    if (h.currentRoutineCard != null)
                                      CurrentRoutineCard(
                                        routine: h.currentRoutineCard!,
                                        next: h.nextRoutineCard,
                                        isUpcoming: h.isDisplayUpcoming,
                                      )
                                    else
                                      const _EmptyRoutineCard(),
                                    const SizedBox(height: 20),
                                    HomeCharacterSection(
                                      character: h.character,
                                    ),
                                    const SizedBox(height: 20),
                                    HomeBottomActions(
                                      completeLabel: h.completeButtonLabel,
                                      primaryEnabled: h.canActOnCurrentSlot,
                                      secondaryEnabled: h.canActOnCurrentSlot,
                                      onComplete: h.canActOnCurrentSlot
                                          ? () => app.completeCurrent()
                                          : null,
                                      onLater: h.canActOnCurrentSlot
                                          ? () => app.snoozeCurrent()
                                          : null,
                                      onSkip: h.canActOnCurrentSlot
                                          ? () => app.skipCurrent()
                                          : null,
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
