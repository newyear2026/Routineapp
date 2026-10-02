import 'package:flutter/material.dart';

import '../../application/home/home_focus_state.dart';
import '../../application/home/home_snapshot.dart';
import '../../data/store/character_pack_catalog.dart';
import '../../domain/models/routine.dart';
import '../../domain/utils/time_minutes.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_pixel_style.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_preset.dart';
import '../ds/animated_cat.dart';
import '../ds/app_status_badge.dart';
import '../ds/routine_mark.dart';
import '../ds/segmented_progress.dart';
import 'pack_time_scene.dart';
import 'starlight_home_motion.dart';
import '../store/character_pack_scope.dart';

/// 홈 첫 카드 — 홈 화면 위젯 카드를 앱 안으로 옮긴 것.
///
/// 배지·남은 시간·진행 칸·다음 루틴·고양이를 위젯과 같은 순서로 그린다.
/// 상태별 내용은 [HomeFocusState] 표를 따른다.
class HomeFocusCard extends StatelessWidget {
  const HomeFocusCard({super.key, required this.home, required this.onTap});

  final HomeSnapshot home;
  final VoidCallback onTap;

  static const _catWidth = 88.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final content = _contentFor(l10n, primary);
    final state = home.focusState;
    final shape = AppPixelStyle.shape(width: 2);
    final timeScene = PackTimeScene.of(context, home.clockTime.hour);
    final cardAtmosphere = timeScene?.cardAtmosphere();
    final starlightPack = CharacterPackScope.currentOf(context).id ==
        CharacterPackCatalog.starlightCat.id;
    final starlightMode = switch (state) {
      HomeFocusState.active => StarlightHomeMode.active,
      HomeFocusState.completed => StarlightHomeMode.complete,
      _ => StarlightHomeMode.idle,
    };

    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: ShapeDecoration(
          gradient: state == HomeFocusState.skipped
              ? AppColors.focusCardMutedGradient
              : context.appTheme.preset.focusCardGradient,
          image: state == HomeFocusState.skipped
              ? null
              : timeScene != null
                  ? DecorationImage(
                      image: ResizeImage(
                        AssetImage(timeScene.cardAsset),
                        width: 1100,
                      ),
                      colorFilter: timeScene.cardLighting,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      filterQuality: FilterQuality.none,
                    )
                  : null,
          shape: shape,
          shadows: const [
            BoxShadow(
              color: AppPixelStyle.shadow,
              offset: AppPixelStyle.heroOffset,
            ),
          ],
        ),
        child: InkWell(
          key: const Key('home-focus-card'),
          customBorder: shape,
          onTap: onTap,
          child: ConstrainedBox(
            // 상태에 따라 진행 칸·다음 일정이 빠져도 풍경 카드의 크기는 유지한다.
            constraints: const BoxConstraints(minHeight: 164),
            child: Stack(
              children: [
                if ((timeScene?.usesTextVeil ?? false) &&
                    state != HomeFocusState.skipped)
                  Positioned.fill(
                    child: ClipPath(
                      clipper: ShapeBorderClipper(shape: shape),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            // Keep the cream RGB at zero alpha: transparent
                            // black introduces a gray band while interpolating.
                            colors: timeScene!.spec.graded
                                ? const [
                                    Color(0xB3FFF9EF),
                                    Color(0x55FFF9EF),
                                    Color(0x00FFF9EF)
                                  ]
                                : const [
                                    Color(0xB3FFF9EF),
                                    Color(0x66FFF9EF),
                                    Colors.transparent
                                  ],
                            stops: timeScene.spec.graded
                                ? const [0, 0.42, 1]
                                : const [0, 0.55, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (cardAtmosphere != null && state != HomeFocusState.skipped)
                  Positioned.fill(
                    child: ClipPath(
                      clipper: ShapeBorderClipper(shape: shape),
                      child: cardAtmosphere,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    14,
                    _catWidth + 4,
                    12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppStatusBadge(label: content.badge, tone: content.tone),
                      const SizedBox(height: 6),
                      _Title(
                        routine: content.routine,
                        text: content.title,
                        muted: state == HomeFocusState.skipped,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        content.line,
                        key: const Key('home-focus-line'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label.copyWith(
                          color: content.lineColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (content.subLine != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          content.subLine!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ],
                      if (content.progress != null) ...[
                        const SizedBox(height: 8),
                        SegmentedProgress(
                          key: const Key('home-focus-progress'),
                          value: content.progress!,
                          color: content.progressColor,
                          height: 10,
                          segmentCount: 12,
                          semanticLabel:
                              '${(content.progress! * 100).round()}%',
                        ),
                      ],
                      if (content.next != null) ...[
                        const SizedBox(height: 10),
                        _NextRow(
                            label: content.nextLabel, routine: content.next!),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  key: const Key('home-focus-cat'),
                  right: 4,
                  bottom: 4,
                  width: _catWidth,
                  height: 96,
                  child: starlightPack
                      ? StarlightHomeMotion(mode: starlightMode)
                      : AnimatedCat(
                          pose: homeCatPose(home),
                          homeMotion: true,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _FocusContent _contentFor(AppLocalizations l10n, Color primary) {
    final routine = home.displayRoutine;
    final timing = home.currentRoutineCard?.timingHint ?? '';
    final progress = (home.currentRoutineCard?.progress ?? 0) / 100;
    final next = home.nextAfterDisplay;
    final nextLabel = l10n.homeFocusNext;

    switch (home.focusState) {
      case HomeFocusState.active:
        return _FocusContent(
          badge: l10n.statusInProgress,
          tone: AppStatusBadgeTone.info,
          routine: routine,
          title: routine!.title,
          line: timing,
          lineColor: primary,
          progress: progress,
          progressColor: primary,
          next: next,
          nextLabel: nextLabel,
        );
      case HomeFocusState.snoozed:
        final until = home.snoozedUntil;
        return _FocusContent(
          badge: l10n.statusSnoozedShort,
          tone: AppStatusBadgeTone.meta,
          routine: routine,
          title: routine!.title,
          line: until == null
              ? timing
              : l10n.homeFocusSnoozedUntil(
                  TimeMinutes.formatHm(until.hour * 60 + until.minute),
                ),
          lineColor: primary,
          progress: progress,
          progressColor: primary.withValues(alpha: 0.5),
          next: next,
          nextLabel: nextLabel,
        );
      case HomeFocusState.completed:
        return _FocusContent(
          badge: l10n.statusCompleted,
          tone: AppStatusBadgeTone.success,
          routine: routine,
          title: routine!.title,
          line: l10n.homeFocusCompleted(home.completedCount),
          lineColor: AppColors.successText,
          progress: 1,
          progressColor: AppColors.success,
          next: next,
          nextLabel: nextLabel,
        );
      case HomeFocusState.skipped:
        return _FocusContent(
          badge: l10n.statusSkippedShort,
          tone: AppStatusBadgeTone.neutral,
          routine: routine,
          title: routine!.title,
          line: l10n.homeFocusSkipped,
          lineColor: AppColors.textMuted,
          next: next,
          nextLabel: nextLabel,
        );
      case HomeFocusState.upcoming:
        return _FocusContent(
          badge: l10n.statusUpcoming,
          tone: AppStatusBadgeTone.warning,
          routine: routine,
          title: routine!.title,
          line: timing,
          lineColor: AppColors.scheduledText,
          subLine: TimeMinutes.formatRange(
            routine.startMinutesFromMidnight,
            routine.endMinutesFromMidnight,
          ),
          next: next,
          nextLabel: nextLabel,
        );
      case HomeFocusState.dayDone:
        final result = home.dayResult;
        return _FocusContent(
          badge: l10n.statusDayDone,
          tone: AppStatusBadgeTone.success,
          title: l10n.homeFocusDayDoneTitle,
          line: [
            l10n.homeFocusDayCount(l10n.statusCompleted, result.completed),
            if (result.skipped > 0)
              l10n.homeFocusDayCount(l10n.statusSkippedShort, result.skipped),
            if (result.missed > 0)
              l10n.homeFocusDayCount(l10n.statusMissed, result.missed),
          ].join(' · '),
          lineColor: AppColors.textMuted,
          next: home.tomorrowFirstRoutine,
          nextLabel: l10n.homeFocusTomorrow,
        );
      case HomeFocusState.empty:
        return _FocusContent(
          badge: l10n.commonToday,
          tone: AppStatusBadgeTone.neutral,
          title: l10n.homeCreateFirstRoutine,
          line: l10n.homeStartYourDay,
          lineColor: AppColors.textMuted,
        );
    }
  }
}

class _FocusContent {
  const _FocusContent({
    required this.badge,
    required this.tone,
    this.routine,
    required this.title,
    required this.line,
    required this.lineColor,
    this.subLine,
    this.progress,
    this.progressColor = AppColors.orbitPrimary,
    this.next,
    this.nextLabel = '',
  });

  final String badge;
  final AppStatusBadgeTone tone;
  final Routine? routine;
  final String title;

  /// 이름 바로 아래 한 줄 — 남은 시간이나 상태 설명. 오른쪽 좁은 칸에 두지 않는다.
  final String line;
  final Color lineColor;
  final String? subLine;
  final double? progress;
  final Color progressColor;
  final Routine? next;
  final String nextLabel;
}

class _Title extends StatelessWidget {
  const _Title(
      {required this.routine, required this.text, required this.muted});

  final Routine? routine;
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final routine = this.routine;
    final style = AppTextStyles.titleScreen.copyWith(
      color: muted ? AppColors.textMuted : null,
    );
    if (routine == null) {
      return Text(text,
          maxLines: 2, overflow: TextOverflow.ellipsis, style: style);
    }
    return Row(
      children: [
        Opacity(
          opacity: muted ? 0.55 : 1,
          child: RoutineMark(
            icon: routine.iconId,
            color: routine.color,
            size: 26,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _NextRow extends StatelessWidget {
  const _NextRow({required this.label, required this.routine});

  final String label;
  final Routine routine;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('home-focus-next'),
        padding: const EdgeInsets.only(top: 8),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.decorationOutline, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: '$label ',
                  children: [
                    TextSpan(
                      text: routine.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              TimeMinutes.formatHm(routine.startMinutesFromMidnight),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}
