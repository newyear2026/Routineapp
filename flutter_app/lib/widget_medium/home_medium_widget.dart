import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_pixel_style.dart';
import '../theme/app_colors.dart';
import '../widgets/ds/pixel_decoration.dart';
import '../data/store/character_pack_catalog.dart';
import '../domain/store/character_pack.dart';
import '../theme/pack_skin.dart';
import '../theme/pack_skin_catalog.dart';
import 'home_medium_widget_view_model.dart';
import 'mini_circular_timetable.dart';
import 'widget_theme.dart';
import 'compact_widget_timeline.dart';

enum HomeWidgetStyle { cards, ring, timeline }

/// Selected card and orbit designs; all copy comes from the shared selector.
class HomeMediumWidget extends StatelessWidget {
  const HomeMediumWidget({
    super.key,
    required this.viewModel,
    this.ringSize = 124,
    this.pack = CharacterPackCatalog.defaultPack,
    this.style = HomeWidgetStyle.ring,
    this.onComplete,
  });

  final HomeMediumWidgetViewModel viewModel;
  final double ringSize;
  final CharacterPack pack;
  final HomeWidgetStyle style;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final skin = PackSkinCatalog.of(pack).widget;
    final ink = skin.textPrimary ?? WidgetTheme.textPrimary;
    final muted = skin.textMuted ?? WidgetTheme.textMuted;
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 300;
      final compactTimeline = narrow && style == HomeWidgetStyle.timeline;
      final dialSize = narrow ? 104.0 : ringSize;
      Widget label(String text, double size, Color color, {int lines = 1}) =>
          Text(text,
              maxLines: lines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: size,
                  height: 1.12,
                  fontWeight: FontWeight.w700,
                  color: color));
      final status = vm.currentRoutineStatusLabel.isEmpty
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: ShapeDecoration(
                  color: skin.accent,
                  shape: AppPixelStyle.shape(steps: 1, width: 1)),
              child: label(vm.currentRoutineStatusLabel, 11,
                  skin.onAccent ?? Colors.white));
      final complete = vm.canComplete
          ? Semantics(
              button: true,
              label: vm.completeLabel,
              child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                      onTap: onComplete,
                      customBorder: AppPixelStyle.shape(steps: 2),
                      child: Ink(
                          height: 40,
                          decoration: ShapeDecoration(
                              color: AppColors.orbitPrimary,
                              shape: AppPixelStyle.shape(steps: 2)),
                          padding: EdgeInsets.symmetric(
                              horizontal: compactTimeline ? 6 : 10),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded,
                                    color: Colors.white,
                                    size: compactTimeline ? 18 : 22),
                                SizedBox(width: compactTimeline ? 3 : 5),
                                Flexible(
                                    child: label(
                                        vm.completeLabel,
                                        compactTimeline ? 13 : 15,
                                        Colors.white))
                              ])))))
          : const SizedBox.shrink();
      final next = Row(children: [
        if (vm.nextRoutineTime.isNotEmpty) ...[
          Flexible(child: label(l10n.commonNext, 12, muted)),
          const SizedBox(width: 5),
          label(vm.nextRoutineTime, 13, muted),
          const SizedBox(width: 5),
        ],
        Expanded(child: label(vm.nextRoutineTitle, 13, ink)),
      ]);
      final divider = Container(
          height: 1,
          color: (skin.border ?? WidgetTheme.border).withValues(alpha: 0.6));
      final timing = vm.remainingDuration.isNotEmpty
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                  Flexible(
                      child: label(
                          vm.remainingDuration, narrow ? 25 : 30, skin.accent)),
                  const SizedBox(width: 4),
                  label(vm.remainingLabel, 13, muted),
                ])
          : label(vm.currentRoutineTimingHint, 13, muted, lines: 2);
      final mascot = Image.asset(pack.assetFor('idle')!,
          filterQuality: FilterQuality.none, fit: BoxFit.contain);
      return SizedBox(
          height: 180,
          child: Container(
              padding: const EdgeInsets.all(12),
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                  gradient: LinearGradient(colors: skin.background),
                  shape: AppPixelStyle.shape(step: 3, steps: 4, width: 1.5)),
              child: Stack(children: [
                Positioned.fill(
                    child: IgnorePointer(
                        child: Opacity(
                            opacity: 0.65,
                            child: _WidgetDecorLayer(skin: skin)))),
                if (style == HomeWidgetStyle.cards)
                  Column(children: [
                    Expanded(
                        child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            Row(children: [
                              status,
                              const SizedBox(width: 6),
                              Expanded(
                                  child: label(
                                      vm.currentRoutineTimeRange, 11, muted))
                            ]),
                            const SizedBox(height: 5),
                            label(
                                vm.currentRoutineTitle, narrow ? 23 : 27, ink),
                            const SizedBox(height: 3),
                            timing,
                          ])),
                      SizedBox(
                          width: narrow ? 67 : 90, height: 90, child: mascot),
                    ])),
                    const SizedBox(height: 5),
                    divider,
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            label(
                                '${l10n.commonNext} ${vm.nextRoutineTime}'
                                    .trim(),
                                12,
                                muted),
                            const SizedBox(height: 2),
                            label(vm.nextRoutineTitle, 15, ink)
                          ])),
                      if (vm.canComplete) ...[
                        const SizedBox(width: 10),
                        SizedBox(width: narrow ? 96 : 120, child: complete)
                      ],
                    ]),
                  ])
                else if (style == HomeWidgetStyle.timeline)
                  Column(children: [
                    Expanded(
                        child: Row(children: [
                      SizedBox(
                          width: narrow ? 52 : 84, height: 84, child: mascot),
                      SizedBox(width: narrow ? 4 : 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            Align(
                                alignment: Alignment.centerLeft, child: status),
                            const SizedBox(height: 2),
                            label(
                                vm.currentRoutineTitle, narrow ? 22 : 26, ink),
                            const SizedBox(height: 2),
                            if (vm.remainingDuration.isNotEmpty)
                              FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        label(vm.remainingDuration,
                                            narrow ? 22 : 26, skin.accent),
                                        const SizedBox(width: 4),
                                        label(vm.remainingLabel, 13, muted),
                                      ]))
                            else
                              label(vm.currentRoutineTimingHint, 12, muted,
                                  lines: 2),
                          ])),
                      if (vm.canComplete) ...[
                        SizedBox(width: narrow ? 4 : 8),
                        Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: SizedBox(
                                width: narrow ? 70 : 90,
                                height: 44,
                                child: complete)),
                      ],
                    ])),
                    if (vm.timelineItems.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      divider,
                      const SizedBox(height: 6),
                      CompactWidgetTimeline(
                          items: vm.timelineItems,
                          nowEpochMs: vm.timelineNowEpochMs,
                          accent: skin.accent,
                          ink: ink,
                          muted: muted),
                    ],
                  ])
                else
                  Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Align(alignment: Alignment.centerLeft, child: status),
                          const SizedBox(height: 6),
                          label(vm.currentRoutineTitle, narrow ? 22 : 26, ink),
                          const SizedBox(height: 4),
                          label(vm.currentRoutineTimeRange, 13, muted),
                          const SizedBox(height: 8),
                          if (vm.canComplete)
                            complete
                          else
                            label(vm.currentRoutineTimingHint, 12, muted,
                                lines: 2),
                          const SizedBox(height: 8),
                          divider,
                          const SizedBox(height: 6),
                          next,
                        ])),
                    const SizedBox(width: 9),
                    SizedBox(
                        width: dialSize,
                        height: 156,
                        child:
                            Stack(alignment: Alignment.bottomCenter, children: [
                          MiniCircularTimetable(
                              segments: vm.ringSegments,
                              currentTime: vm.currentTime,
                              activeSegmentId: vm.activeSegmentId,
                              pointerAngleRad: vm.pointerAngleRad,
                              centerLabel: vm.remainingDuration.isEmpty
                                  ? vm.centerTimeLabel
                                  : vm.remainingLabel,
                              centerValue: vm.remainingDuration.isEmpty
                                  ? null
                                  : vm.remainingDuration,
                              labelsInside: true,
                              size: dialSize,
                              palette: skin.dial),
                          Positioned(
                              bottom: dialSize - 3,
                              width: 43,
                              height: 38,
                              child: mascot),
                        ])),
                  ])
              ])));
    });
  }
}

/// 위젯 바탕 장식 — [PackWidgetSkin.decor]가 고른다.
class _WidgetDecorLayer extends StatelessWidget {
  const _WidgetDecorLayer({required this.skin});

  final PackWidgetSkin skin;

  @override
  Widget build(BuildContext context) => switch (skin.decor) {
        WidgetDecor.sky => Opacity(
            opacity: 0.45,
            child: Image.asset('assets/decorations/home-sky.png',
                fit: BoxFit.fill, filterQuality: FilterQuality.none),
          ),
        WidgetDecor.garden => const _GardenDecor(),
        WidgetDecor.stars => const _StargazerDecor(),
        WidgetDecor.stamp => Align(
            alignment: Alignment.topRight,
            child: Opacity(
              opacity: 0.7,
              child: Image.asset(
                'assets/decorations/${skin.decorAsset}.png',
                width: 27,
                height: 27,
                filterQuality: FilterQuality.none,
              ),
            ),
          ),
        WidgetDecor.forest => Opacity(
            opacity: 0.30,
            child: Image.asset(
              'assets/pack_backgrounds/squirrel-forest.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
          ),
        WidgetDecor.dawn => Opacity(
            opacity: 0.35,
            child: Image.asset(
              'assets/pack_backgrounds/rabbit-dawn.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
          ),
        WidgetDecor.mooncloud => Opacity(
            opacity: 0.28,
            child: Image.asset(
              'assets/pack_backgrounds/sheep-sky.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
          ),
        WidgetDecor.teashop => Opacity(
            opacity: 0.28,
            child: Image.asset(
              'assets/pack_backgrounds/redpanda-teashop.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
          ),
        WidgetDecor.seaside => Opacity(
            opacity: 0.30,
            child: Image.asset(
              'assets/pack_backgrounds/otter-seaside.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
          ),
        WidgetDecor.snowwalk => Opacity(
            opacity: 0.30,
            child: Image.asset(
              'assets/pack_backgrounds/penguin-snowpath.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
          ),
      };
}

class _GardenDecor extends StatelessWidget {
  const _GardenDecor();

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned(
          top: 8,
          left: 4,
          child: Image.asset('assets/decorations/garden-leaf.png',
              width: 15, filterQuality: FilterQuality.none),
        ),
        Positioned(
          top: 13,
          right: 6,
          child: Image.asset('assets/decorations/garden-leaf.png',
              width: 17, filterQuality: FilterQuality.none),
        ),
        Positioned(
          bottom: -5,
          right: -5,
          child: Image.asset('assets/decorations/garden-daisy.png',
              width: 38, filterQuality: FilterQuality.none),
        ),
      ]);
}

class _StargazerDecor extends StatelessWidget {
  const _StargazerDecor();

  @override
  Widget build(BuildContext context) => const Stack(children: [
        Positioned(
          top: 6,
          left: 8,
          child: PixelSpark(size: 6, color: Color(0xFFF4C430)),
        ),
        Positioned(
          top: 12,
          right: 78,
          child: PixelSpark(size: 5, color: Color(0xFFFFF0BB)),
        ),
        Positioned(
          bottom: 9,
          left: 55,
          child: PixelSpark(size: 5, color: Color(0xFF9DE2DF)),
        ),
      ]);
}
