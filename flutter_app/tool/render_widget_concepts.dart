// 시스템 홈 위젯(Medium) 픽셀 시안 렌더러 — **제품 코드는 건드리지 않는다**.
//
// 앱은 픽셀 전환을 마쳤는데 위젯 세 벌(Flutter·SwiftUI·XML+Canvas)은 옛 라운드
// 디자인 그대로다. 네이티브 두 벌로 옮기기 전에 여기서 시안을 먼저 확정한다.
//
// flutter test tool/render_widget_concepts.dart --dart-define=PREVIEW_FONT=/path/to/korean.ttf
// 결과: output/pixel-preview/widget-concepts.png
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/theme/app_colors.dart';
import 'package:routine_timer/theme/app_pixel_style.dart';
import 'package:routine_timer/theme/app_text_styles.dart';
import 'package:routine_timer/theme/app_theme.dart';
import 'package:routine_timer/widget_medium/home_medium_widget_view_model.dart';
import 'package:routine_timer/widget_medium/medium_ring_segment.dart';

import '../test/support/localization.dart';

/// 실제 Medium 위젯 폭. iPhone 390pt에서 329×155, Android 4×2는 250dp까지 좁아진다.
const _wide = Size(330, 155);
const _narrow = Size(250, 140);

/// iOS·Android 런처가 위젯 바깥 모서리에 씌우는 라운드. 우리가 못 없앤다.
const _systemCorner = 22.0;

void main() {
  testWidgets('홈 위젯 픽셀 시안', (tester) async {
    await _loadFonts();
    tester.view
      ..physicalSize = const Size(700, 730)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final vm = HomeMediumWidgetViewModel.dummy(testL10n);
    final key = GlobalKey();

    await tester.pumpWidget(localizedApp(
      home: Theme(
        data: buildRoutineTheme(fontFamily: 'PreviewKorean'),
        child: Material(
          color: Colors.transparent,
          child: RepaintBoundary(key: key, child: _Sheet(vm: vm)),
        ),
      ),
    ));
    await tester.runAsync(() async {
      for (final pose in ['idle']) {
        await precacheImage(
          AssetImage('assets/characters/cat_starlight/v1/approved/$pose.png'),
          key.currentContext!,
        );
      }
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    final out = File('output/pixel-preview/widget-concepts.png');
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(bytes!);
  });
}

Future<void> _loadFonts() async {
  const fontPath = String.fromEnvironment('PREVIEW_FONT');
  if (fontPath.isEmpty) throw StateError('PREVIEW_FONT에 로컬 한글 폰트를 지정하세요.');
  final korean = FontLoader('PreviewKorean')
    ..addFont(
        Future.value(ByteData.sublistView(File(fontPath).readAsBytesSync())));
  await korean.load();
  final pixel = FontLoader('PixelifySans')
    ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
  await pixel.load();
}

// ─────────────────────────────────────────────────────────────
// 시안 대지
// ─────────────────────────────────────────────────────────────

class _Sheet extends StatelessWidget {
  const _Sheet({required this.vm});

  final HomeMediumWidgetViewModel vm;

  @override
  Widget build(BuildContext context) => Container(
        // 위젯 바탕이 크림이라 흰 대지 위에서는 경계가 사라진다. 홈 화면
        // 배경 역할의 회색 면 위에 얹어 위젯 면적을 드러낸다.
        color: const Color(0xFF8E8AA0),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final concept in <(String, String, Widget Function(Size))>[
              ('A안 — 픽셀 이식', '지금 배치 그대로, 모서리·배지·칩·원판만 픽셀로',
                  (size) => _ConceptA(vm: vm, size: size)),
              ('B안 — 흰 픽셀 패널', 'OS가 자르는 바깥 모서리 안쪽에 카드를 한 겹 넣는다',
                  (size) => _ConceptB(vm: vm, size: size)),
              ('C안 — 고양이 동반', '원판을 주인공으로 키우고 앱 홈의 캐릭터를 데려온다',
                  (size) => _ConceptC(vm: vm, size: size)),
            ]) ...[
              Text(concept.$1,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(concept.$2,
                  style: const TextStyle(
                      color: Color(0xFFE6E3EE),
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Framed(size: _wide, child: concept.$3(_wide)),
                  const SizedBox(width: 16),
                  _Framed(size: _narrow, child: concept.$3(_narrow)),
                ],
              ),
              const SizedBox(height: 18),
            ],
            const SizedBox(height: 2),
            Text('왼쪽 330×155(iPhone Medium) · 오른쪽 250×140(Android 최소 폭)',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

/// OS가 씌우는 라운드 마스크까지 포함해서 본다. 계단 모서리를 바깥 테두리에
/// 쓸 수 없다는 제약이 시안 단계에서 눈에 보여야 한다.
class _Framed extends StatelessWidget {
  const _Framed({required this.size, required this.child});

  final Size size;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(_systemCorner),
        child: SizedBox(width: size.width, height: size.height, child: child),
      );
}

// ─────────────────────────────────────────────────────────────
// A안 — 픽셀 이식
// ─────────────────────────────────────────────────────────────

class _ConceptA extends StatelessWidget {
  const _ConceptA({required this.vm, required this.size});

  final HomeMediumWidgetViewModel vm;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final narrow = size.width < 300;
    final dial = narrow ? 92.0 : 108.0;
    return Container(
      color: AppColors.pageBackground,
      padding: EdgeInsets.fromLTRB(narrow ? 11 : 14, 10, narrow ? 10 : 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PixelBadge(label: vm.currentRoutineStatusLabel),
                SizedBox(height: narrow ? 5 : 7),
                _Title(vm.currentRoutineTitle, size: narrow ? 17 : 20),
                const SizedBox(height: 2),
                _Hint(vm.currentRoutineTimingHint, size: narrow ? 12 : 13),
                SizedBox(height: narrow ? 7 : 10),
                _PixelNextChip(
                  title: vm.nextRoutineTitle,
                  time: vm.nextRoutineTime,
                  narrow: narrow,
                ),
              ],
            ),
          ),
          SizedBox(width: narrow ? 8 : 10),
          _PixelDial(vm: vm, size: dial),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// B안 — 흰 픽셀 패널
// ─────────────────────────────────────────────────────────────

class _ConceptB extends StatelessWidget {
  const _ConceptB({required this.vm, required this.size});

  final HomeMediumWidgetViewModel vm;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final dial = size.width >= 300 ? 100.0 : 88.0;
    return Container(
      color: AppColors.pageBackground,
      padding: const EdgeInsets.all(9),
      child: Container(
        decoration: ShapeDecoration(
          color: AppColors.orbitSurface,
          shape: AppPixelStyle.shape(),
          shadows: const [
            BoxShadow(color: AppPixelStyle.shadow, offset: Offset(3, 3)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 앱 홈의 포커스 스트립과 같은 어법: 캡슐 배지 대신 보라 라벨.
                  Text(
                    vm.currentRoutineStatusLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.orbitPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _Title(vm.currentRoutineTitle,
                      size: size.width >= 300 ? 20 : 18),
                  const SizedBox(height: 3),
                  _Hint(vm.currentRoutineTimingHint),
                  const SizedBox(height: 9),
                  Container(height: 1.5, color: AppColors.orbitBorder),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const _Marker(color: AppColors.decorationSpark),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          vm.nextRoutineTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        vm.nextRoutineTime,
                        style: AppTextStyles.clock.copyWith(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _PixelDial(vm: vm, size: dial, onWhite: true),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// C안 — 고양이 동반
// ─────────────────────────────────────────────────────────────

class _ConceptC extends StatelessWidget {
  const _ConceptC({required this.vm, required this.size});

  final HomeMediumWidgetViewModel vm;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final narrow = size.width < 300;
    final dial = narrow ? 106.0 : 124.0;
    final cat = narrow ? 36.0 : 46.0;
    return Container(
      color: AppColors.pageBackground,
      padding: EdgeInsets.fromLTRB(narrow ? 9 : 12, 8, narrow ? 9 : 12, 8),
      // 고양이는 정보 위에 얹지 않고 오른쪽 아래 빈 자리에 앉힌다.
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _PixelDial(vm: vm, size: dial, showLabel: false),
              SizedBox(width: narrow ? 9 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      vm.currentRoutineStatusLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.orbitPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    _Title(vm.currentRoutineTitle, size: narrow ? 17 : 19),
                    const SizedBox(height: 2),
                    _Hint(vm.currentRoutineTimingHint, size: narrow ? 12 : 13),
                    SizedBox(height: narrow ? 8 : 10),
                    Padding(
                      // 고양이 자리를 비워 둔다.
                      padding: EdgeInsets.only(right: cat + 4),
                      child: Row(
                        children: [
                          const _Marker(color: AppColors.decorationSpark),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              vm.nextRoutineTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: narrow ? 12 : 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            vm.nextRoutineTime,
                            style: AppTextStyles.clock.copyWith(
                              fontSize: narrow ? 12 : 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 3,
            bottom: 2,
            child: Image.asset(
              'assets/characters/cat_starlight/v1/approved/idle.png',
              width: cat,
              filterQuality: FilterQuality.none,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 공용 조각
// ─────────────────────────────────────────────────────────────

class _Title extends StatelessWidget {
  const _Title(this.text, {required this.size});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          height: 1.15,
        ),
      );
}

class _Hint extends StatelessWidget {
  const _Hint(this.text, {this.size = 13});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
      );
}

/// 루틴 식별 색은 원 대신 테두리 있는 사각 표식 (UI_STANDARDS 픽셀 전환 1차).
class _Marker extends StatelessWidget {
  const _Marker({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: AppPixelStyle.outline, width: 1.2),
        ),
      );
}

class _PixelBadge extends StatelessWidget {
  const _PixelBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: ShapeDecoration(
          color: AppColors.orbitPrimary,
          // 작은 배지는 계단 수를 1로 줄인다 (별빛 테마 공통 기준).
          shape: AppPixelStyle.shape(steps: 1, width: 1.2),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
}

class _PixelNextChip extends StatelessWidget {
  const _PixelNextChip({
    required this.title,
    required this.time,
    this.narrow = false,
  });

  final String title;
  final String time;
  final bool narrow;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 9, vertical: narrow ? 4 : 6),
        decoration: ShapeDecoration(
          color: AppColors.orbitSurface,
          shape: AppPixelStyle.shape(steps: 2),
        ),
        child: Row(
          children: [
            const _Marker(color: AppColors.decorationSpark),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: narrow ? 12 : 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              time,
              style: AppTextStyles.clock.copyWith(
                fontSize: narrow ? 12 : 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
}

/// 앱 홈의 계단 원판 + 24시간 링을 위젯 크기로 옮긴 것.
///
/// 제품의 [PixelOrbitPlate]는 계단 한 칸을 `size/146`으로 잡아서 100px 근처에서는
/// 한 칸이 0.7px이 된다 — 계단이 사라지고 그냥 매끈한 원이 된다. 여기서는
/// 칸 크기를 **고정 픽셀**로 두어 작은 크기에서도 픽셀로 읽히게 했다.
/// 링도 마찬가지로 기준 크기를 292 → 150으로 낮춰 선을 굵게 잡았다.
class _PixelDial extends StatelessWidget {
  const _PixelDial({
    required this.vm,
    required this.size,
    this.onWhite = false,
    this.showLabel = true,
  });

  final HomeMediumWidgetViewModel vm;
  final double size;
  final bool onWhite;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final now = vm.currentTime.hour * 60 + vm.currentTime.minute;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _ConceptPlate(onWhite: onWhite),
          ),
          CustomPaint(
            size: Size.square(size),
            painter: _ConceptRing(segments: vm.ringSegments, nowMinutes: now),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${vm.currentTime.hour.toString().padLeft(2, '0')}:'
                '${vm.currentTime.minute.toString().padLeft(2, '0')}',
                style: AppTextStyles.clock.copyWith(fontSize: size * 0.21),
              ),
              if (showLabel) ...[
                SizedBox(height: size * 0.03),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.orbitSurfaceSoft,
                    border: Border.all(color: AppColors.orbitBorder),
                  ),
                  child: Text(
                    vm.centerTimeLabel,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ConceptPlate extends CustomPainter {
  const _ConceptPlate({required this.onWhite});

  final bool onWhite;

  /// 계단 한 칸(px). 작은 위젯에서도 픽셀이 보이도록 고정값을 쓴다.
  static const step = 2.5;

  Path _disk(Offset center, double radius) {
    final halfRows = (radius / step).ceil();
    final right = <Offset>[];
    final left = <Offset>[];
    for (var i = -halfRows; i < halfRows; i++) {
      final y = i * step;
      final midY = y + step / 2;
      final half =
          (math.sqrt(math.max(0, radius * radius - midY * midY)) / step + 0.5)
                  .floor() *
              step;
      if (half == 0) continue;
      right.addAll([center + Offset(half, y), center + Offset(half, y + step)]);
      left.addAll([center + Offset(-half, y), center + Offset(-half, y + step)]);
    }
    return Path()..addPolygon([...right, ...left.reversed], true);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final plate = _disk(center, size.width * 0.48);
    if (!onWhite) {
      canvas.drawPath(
        plate.shift(const Offset(2, 2)),
        Paint()
          ..color = AppPixelStyle.shadow
          ..isAntiAlias = false,
      );
    }
    canvas.drawPath(
      plate,
      Paint()
        ..color = AppColors.dialSurface
        ..isAntiAlias = false,
    );
    canvas.drawPath(
      plate,
      Paint()
        ..color = AppPixelStyle.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..isAntiAlias = false,
    );
    canvas.drawPath(
      _disk(center, size.width * 0.335),
      Paint()
        ..color = AppColors.orbitSurface
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(covariant _ConceptPlate old) => old.onWhite != onWhite;
}

/// 제품 [OrbitRingPainter]와 같은 형태·좌표계. 다른 것은 두 가지뿐이다.
///  - 기준 크기 292 → 150: 100px 근처에서 선이 실오라기처럼 얇아지지 않게.
///  - 24개 눈금 → 6개(4시간 간격): 이 크기에서 24개는 뭉쳐서 회색 띠가 된다.
class _ConceptRing extends CustomPainter {
  const _ConceptRing({required this.segments, required this.nowMinutes});

  final List<MediumRingSegment> segments;
  final int nowMinutes;

  static const referenceSize = 150.0;
  static const radiusFactor = 0.395;
  static const gapRad = 0.05;

  double _rad(num minutes) => (minutes / (24 * 60)) * 2 * math.pi - math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / referenceSize;
    final radius = size.width * radiusFactor;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..isAntiAlias = false
        ..color = AppColors.orbitHalo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9 * scale
        ..strokeCap = StrokeCap.butt,
    );

    for (var hour = 0; hour < 24; hour += 4) {
      final angle = _rad(hour * 60);
      final isMajor = hour % 12 == 0;
      final base = radius - 9 * scale / 2 - 7 * scale;
      final length = (isMajor ? 9 : 6) * scale;
      canvas.drawLine(
        Offset(center.dx + math.cos(angle) * base,
            center.dy + math.sin(angle) * base),
        Offset(center.dx + math.cos(angle) * (base - length),
            center.dy + math.sin(angle) * (base - length)),
        Paint()
          ..isAntiAlias = false
          ..color = AppColors.textMuted.withValues(alpha: isMajor ? 0.7 : 0.45)
          ..strokeWidth = (isMajor ? 2.6 : 1.8) * scale
          ..strokeCap = StrokeCap.butt,
      );
    }

    for (final segment in segments) {
      final sweep = (segment.sweepMinutes / (24 * 60)) * 2 * math.pi;
      if (sweep <= 0) continue;
      canvas.drawArc(
        rect,
        _rad(segment.startMinutesFromMidnight) + gapRad,
        math.max(0.03, sweep - gapRad * 2),
        false,
        Paint()
          ..isAntiAlias = false
          ..color = segment.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11 * scale
          ..strokeCap = StrokeCap.butt,
      );
    }

    final nowRad = _rad(nowMinutes);
    final nowCenter = Offset(
      center.dx + math.cos(nowRad) * (radius + 3 * scale),
      center.dy + math.sin(nowRad) * (radius + 3 * scale),
    );
    canvas.drawLine(
      center,
      nowCenter,
      Paint()
        ..isAntiAlias = false
        ..color = AppColors.orbitPrimary.withValues(alpha: 0.5)
        ..strokeWidth = 1.5 * scale,
    );
    canvas.drawRect(
      Rect.fromCenter(center: nowCenter, width: 12 * scale, height: 12 * scale),
      Paint()
        ..isAntiAlias = false
        ..color = AppColors.orbitSurface,
    );
    canvas.drawRect(
      Rect.fromCenter(center: nowCenter, width: 8 * scale, height: 8 * scale),
      Paint()
        ..isAntiAlias = false
        ..color = AppColors.orbitPrimary,
    );
  }

  @override
  bool shouldRepaint(covariant _ConceptRing old) =>
      old.nowMinutes != nowMinutes;
}
