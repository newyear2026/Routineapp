import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_pixel_style.dart';
import '../widgets/ds/pixel_icon.dart';
import 'home_medium_widget_view_model.dart';
import 'mini_circular_timetable.dart';
import 'widget_theme.dart';

/// 시스템 Medium 위젯과 앱 미리보기가 공유하는 구성.
/// 현재 루틴을 먼저 읽고, 오른쪽 원판에서 하루의 위치를 확인한다.
class HomeMediumWidget extends StatelessWidget {
  const HomeMediumWidget({
    super.key,
    required this.viewModel,
    this.ringSize = 124,
    this.characterPackId = 'cat_starlight',
  });

  final HomeMediumWidgetViewModel viewModel;
  final double ringSize;
  final String characterPackId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 300;
      final garden = characterPackId == 'poodle_garden';
      final accent = garden ? const Color(0xFF078F96) : WidgetTheme.accent;
      final dialSize = narrow ? 84.0 : ringSize.clamp(0.0, 112.0);
      final mascotSize = narrow ? 40.0 : 50.0;
      return SizedBox(
        height: narrow ? 140 : 155,
        child: Container(
          padding: EdgeInsets.fromLTRB(narrow ? 7 : 10, 8, narrow ? 7 : 10, 8),
          decoration: ShapeDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: garden
                  ? const [Color(0xFFF7F0FF), Color(0xFFD4F7E8)]
                  : const [Color(0xFFFFF4DC), Color(0xFFE6D8FF)],
            ),
            shape: AppPixelStyle.shape(width: 1.5),
            shadows: const [
              BoxShadow(
                color: AppPixelStyle.shadow,
                offset: Offset(2, 3),
              )
            ],
          ),
          child: Stack(children: [
            Positioned.fill(
              child: IgnorePointer(
                child: garden
                    ? const _GardenDecor()
                    : Opacity(
                        opacity: 0.45,
                        child: Image.asset('assets/decorations/home-sky.png',
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.none),
                      ),
              ),
            ),
            Row(children: [
              SizedBox(
                width: mascotSize,
                child: OverflowBox(
                  alignment: Alignment.bottomLeft,
                  maxWidth: narrow ? 55 : 70,
                  maxHeight: narrow ? 55 : 70,
                  child: Transform.translate(
                    offset: Offset(narrow ? -8 : -10, 0),
                    child: Image.asset(
                      garden
                          ? 'assets/characters/poodle_garden/v1/approved/idle.png'
                          : 'assets/characters/cat_starlight/v1/approved/idle.png',
                      width: narrow ? 55 : 70,
                      height: narrow ? 55 : 70,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ),
              ),
              SizedBox(width: narrow ? 3 : 5),
              Expanded(
                child: _RoutineColumn(
                  vm: viewModel,
                  nextLabel: l10n.commonNext,
                  narrow: narrow,
                  accent: accent,
                ),
              ),
              SizedBox(width: narrow ? 4 : 7),
              Container(width: 1, color: WidgetTheme.border),
              SizedBox(width: narrow ? 2 : 5),
              MiniCircularTimetable(
                segments: viewModel.ringSegments,
                currentTime: viewModel.currentTime,
                activeSegmentId: viewModel.activeSegmentId,
                pointerAngleRad: viewModel.pointerAngleRad,
                centerLabel: viewModel.centerTimeLabel,
                size: dialSize,
              ),
            ]),
          ]),
        ),
      );
    });
  }
}

class _RoutineColumn extends StatelessWidget {
  const _RoutineColumn({
    required this.vm,
    required this.nextLabel,
    required this.narrow,
    required this.accent,
  });

  final HomeMediumWidgetViewModel vm;
  final String nextLabel;
  final bool narrow;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          if (vm.currentRoutineStatusLabel.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: ShapeDecoration(
                color: accent,
                shape: AppPixelStyle.shape(steps: 1, width: 1.2),
              ),
              child: Text(
                vm.currentRoutineStatusLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: WidgetTheme.captionSize,
                  fontWeight: FontWeight.w800,
                  color: WidgetTheme.onAccent,
                  height: 1.1,
                ),
              ),
            ),
            SizedBox(height: narrow ? 5 : 7),
          ],
          Text(
            vm.currentRoutineTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: narrow ? 17 : 22,
              fontWeight: FontWeight.w800,
              color: WidgetTheme.textPrimary,
              height: 1.08,
            ),
          ),
          if (vm.currentRoutineTimingHint.isNotEmpty) ...[
            const SizedBox(height: 5),
            _TimingHint(vm.currentRoutineTimingHint, narrow: narrow),
          ],
          const Spacer(),
          Container(height: 1, color: WidgetTheme.border),
          SizedBox(height: narrow ? 6 : 8),
          Row(children: [
            PixelIcon(PixelGlyph.progress,
                size: narrow ? 15 : 17, color: WidgetTheme.textMuted),
            const SizedBox(width: 5),
            // 라벨과 제목을 한 문단으로 묶는다. 라벨을 따로 두면 «Siguiente»
            // 처럼 긴 라벨이 제목 몫을 다 먹고 줄이 넘친다. 한 문단이면
            // 넘칠 때 제목 끝이 말줄임표로 줄어든다.
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: nextLabel,
                    style: TextStyle(
                        fontSize: narrow ? 11 : 12,
                        fontWeight: FontWeight.w700,
                        color: WidgetTheme.textMuted),
                  ),
                  const WidgetSpan(child: SizedBox(width: 5)),
                  TextSpan(text: vm.nextRoutineTitle),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: narrow ? 12 : WidgetTheme.bodySize,
                    fontWeight: FontWeight.w800,
                    color: WidgetTheme.textPrimary),
              ),
            ),
            if (vm.nextRoutineTime.isNotEmpty) ...[
              const SizedBox(width: 4),
              // 작은 시각은 격자 숫자보다 본문 글꼴이 잘 읽힌다. 앱 첫 카드의
              // «다음» 줄과 같은 모양이다.
              Text(vm.nextRoutineTime,
                  style: TextStyle(
                    fontSize: narrow ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: WidgetTheme.textMuted,
                  )),
            ],
          ]),
          const Spacer(),
        ],
      );
}

class _TimingHint extends StatelessWidget {
  const _TimingHint(this.text, {required this.narrow});

  final String text;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    // 한국어의 마지막 '남음'만 중립색으로 두어 시안의 숫자 강조를 살린다.
    // 다른 언어는 번역된 문구를 쪼개지 않고 한 줄 그대로 보여준다.
    final suffixStart = text.endsWith(' 남음') ? text.length - 3 : text.length;
    final duration = RegExp(r'\d+(?:시간\s*\d+)?분|\d+시간')
        .firstMatch(text.substring(0, suffixStart));
    final base = TextStyle(
      fontSize: narrow ? 11 : WidgetTheme.bodySize,
      fontWeight: FontWeight.w700,
      color: WidgetTheme.accent,
      height: 1.15,
    );
    return Text.rich(
      TextSpan(children: [
        if (duration == null)
          TextSpan(text: text.substring(0, suffixStart))
        else ...[
          TextSpan(text: text.substring(0, duration.start)),
          TextSpan(
            text: duration.group(0),
            style: TextStyle(
              fontSize: narrow ? 11 : 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: text.substring(duration.end, suffixStart)),
        ],
        if (suffixStart < text.length)
          TextSpan(
            text: text.substring(suffixStart),
            style: const TextStyle(color: WidgetTheme.textMuted),
          ),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: base,
    );
  }
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
