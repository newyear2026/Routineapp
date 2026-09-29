// 스플래시 브랜드 시안 렌더러 — **제품 코드는 건드리지 않는다**.
//
// 앱이 픽셀과 캐릭터로 바뀌면서 사실상 다른 물건이 됐다. 스플래시는 «이 앱이
// 무엇인가»를 말하는 자리인데, 지금은 매끈한 벡터 궤도와 옛 팔레트
// 그라데이션이라 뒤따라오는 화면과 다른 앱처럼 보인다. 기존 마크를 손보는
// 대신 지금의 톤에서 다시 세운다.
//
// 세 안은 «무엇이 주인공인가»로 갈린다 — 마크 / 캐릭터 / 제품.
//
// 두 가지 제약을 안고 그린다.
//  - 이름이 «하루 한 바퀴»다. 원을 버리면 이름과 마크의 연결이 끊긴다.
//  - 알림 아이콘은 24dp 흑백 실루엣이다(generate_notification_icon 참고).
//    고양이는 그 크기에서 뭉개지므로, 아이콘 자리를 맡을 도형이 따로 필요하다.
//
// flutter test tool/render_splash_concepts.dart --dart-define=PREVIEW_FONT=/path/to/korean.ttf
// 결과: output/pixel-preview/splash-concepts.png
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/theme/app_colors.dart';
import 'package:routine_timer/theme/app_pixel_style.dart';
import 'package:routine_timer/theme/app_spacing.dart';
import 'package:routine_timer/theme/app_text_styles.dart';
import 'package:routine_timer/theme/app_theme.dart';
import 'package:routine_timer/theme/routine_palette.dart';

import '../test/support/localization.dart';

const _phone = Size(390, 844);
const _shrink = 0.6;

const _cat = 'assets/characters/cat_starlight/v1/approved';

void main() {
  testWidgets('스플래시 브랜드 시안', (tester) async {
    await _loadFonts();
    tester.view
      ..physicalSize = const Size(1060, 720)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    await tester.pumpWidget(localizedApp(
      home: Theme(
        data: buildRoutineTheme(fontFamily: 'PreviewKorean'),
        child: Material(
          color: Colors.transparent,
          child: RepaintBoundary(key: key, child: const _Sheet()),
        ),
      ),
    ));
    await tester.runAsync(() async {
      for (final pose in ['idle', 'guide']) {
        await precacheImage(AssetImage('$_cat/$pose.png'), key.currentContext!);
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
    final out = File('output/pixel-preview/splash-concepts.png');
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
  const _Sheet();

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF3B3550),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('스플래시 브랜드 시안 — 무엇이 주인공인가',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text('셋 다 원을 남긴다 — 이름이 «하루 한 바퀴»이므로 원이 곧 이름이다',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Framed(
                  title: '1안 — 마크가 주인공',
                  note: '궤도를 픽셀에서 다시 세운다. 해·달·루틴 블록',
                  icon: '아이콘: 이 마크 그대로',
                  child: _ConceptMark(),
                ),
                SizedBox(width: 14),
                _Framed(
                  title: '2안 — 캐릭터가 주인공',
                  note: '고양이를 앞세우고 원은 뒤로 물러나 달이 된다',
                  icon: '아이콘: 원을 따로 써야 함',
                  child: _ConceptCharacter(),
                ),
                SizedBox(width: 14),
                _Framed(
                  title: '3안 — 제품이 주인공',
                  note: '앱이 실제로 그리는 하루 원판을 그대로 세운다',
                  icon: '아이콘: 원판 단순화 필요',
                  child: _ConceptProduct(),
                ),
                SizedBox(width: 14),
                _Framed(
                  title: '4안 — 마크 + 캐릭터',
                  note: '1안의 마크는 아이콘을 맡고, 고양이는 스플래시만 데운다',
                  icon: '아이콘: 1안 마크 그대로',
                  child: _ConceptBoth(),
                ),
              ],
            ),
          ],
        ),
      );
}

class _Framed extends StatelessWidget {
  const _Framed({
    required this.title,
    required this.note,
    required this.icon,
    required this.child,
  });

  final String title;
  final String note;
  final String icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: _phone.width * _shrink,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 1),
            SizedBox(
              height: 28,
              child: Text(note,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 10,
                      height: 1.3)),
            ),
            const SizedBox(height: 5),
            ClipRect(
              child: SizedBox(
                width: _phone.width * _shrink,
                height: _phone.height * _shrink,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox(
                    width: _phone.width,
                    height: _phone.height,
                    child: child,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(icon,
                style: TextStyle(
                    color: icon == '—'
                        ? Colors.white.withValues(alpha: 0.5)
                        : const Color(0xFFFFD08A),
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// 1안 — 마크가 주인공
// ─────────────────────────────────────────────────────────────

class _ConceptMark extends StatelessWidget {
  const _ConceptMark();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AppColors.pageBackground,
        child: Stack(
          children: [
            _Sky(dense: false),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomPaint(
                    size: Size.square(212),
                    painter: _PixelDayMark(),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  _Words(),
                ],
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// 2안 — 캐릭터가 주인공
// ─────────────────────────────────────────────────────────────

class _ConceptCharacter extends StatelessWidget {
  const _ConceptCharacter();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.pageBackground,
        child: Stack(
          children: [
            const _Sky(dense: true),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 원은 버리지 않고 고양이 뒤로 물러나 달이 된다.
                        const CustomPaint(
                          size: Size.square(250),
                          painter: _PixelDisk(
                            radius: 0.40,
                            fill: AppColors.dialSurface,
                            outline: true,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Image.asset(
                            '$_cat/idle.png',
                            width: 190,
                            filterQuality: FilterQuality.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _Words(),
                ],
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// 3안 — 제품이 주인공
// ─────────────────────────────────────────────────────────────

class _ConceptProduct extends StatelessWidget {
  const _ConceptProduct();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.pageBackground,
        child: Stack(
          children: [
            const _Sky(dense: true),
            Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const CustomPaint(
                      size: Size.square(268),
                      painter: _PixelDisk(
                        radius: 0.48,
                        fill: AppColors.dialSurface,
                        outline: true,
                        innerFill: AppColors.orbitSurface,
                      ),
                    ),
                    const CustomPaint(
                      size: Size.square(268),
                      painter: _DayRing(),
                    ),
                    // 시계 자리에 이름을 넣는다 — 제품 그 자체가 마크가 된다.
                    const _Words(compact: true),
                    Positioned(
                      right: 2,
                      bottom: 4,
                      child: Image.asset(
                        '$_cat/guide.png',
                        width: 82,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// 4안 — 마크가 아이콘을 맡고, 캐릭터는 스플래시를 데운다
// ─────────────────────────────────────────────────────────────

class _ConceptBoth extends StatelessWidget {
  const _ConceptBoth();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.pageBackground,
        child: Stack(
          children: [
            const _Sky(dense: true),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 마크는 1안 그대로 — 아이콘·알림까지 이 한 벌로 간다.
                  SizedBox(
                    width: 260,
                    height: 214,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Align(
                          alignment: Alignment.topCenter,
                          child: CustomPaint(
                            size: Size.square(190),
                            painter: _PixelDayMark(),
                          ),
                        ),
                        // 고양이는 마크에 기대 앉는다. 아이콘에는 들어가지 않는다.
                        Positioned(
                          right: 4,
                          bottom: 0,
                          child: Image.asset(
                            '$_cat/idle.png',
                            width: 92,
                            filterQuality: FilterQuality.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _Words(),
                ],
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// 공용 조각
// ─────────────────────────────────────────────────────────────

class _Words extends StatelessWidget {
  const _Words({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            testL10n.appName,
            style: compact
                ? AppTextStyles.hero.copyWith(fontSize: 23)
                : AppTextStyles.hero,
          ),
          SizedBox(height: compact ? 2 : AppSpacing.sm),
          Text(
            testL10n.appTagline,
            style: compact
                ? AppTextStyles.label.copyWith(fontSize: 11)
                : AppTextStyles.label,
          ),
        ],
      );
}

/// 홈 시간표 장면과 같은 어휘 — 달·구름·별.
class _Sky extends StatelessWidget {
  const _Sky({required this.dense});

  final bool dense;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          if (dense) ...[
            const Positioned(left: 24, top: 122, child: _Moon(size: 42)),
            const Positioned(left: 0, top: 238, child: _Cloud(width: 60)),
            const Positioned(right: 0, top: 170, child: _Cloud(width: 52)),
            const Positioned(left: 10, bottom: 176, child: _Cloud(width: 66)),
            const Positioned(right: 20, bottom: 232, child: _Cloud(width: 46)),
          ],
          const Positioned(right: 42, top: 132, child: _Star(size: 15)),
          const Positioned(
              left: 62, top: 196, child: _Star(size: 12, dim: true)),
          const Positioned(right: 74, top: 268, child: _Star(size: 12)),
          const Positioned(
              left: 88, bottom: 208, child: _Star(size: 13, dim: true)),
          const Positioned(
              right: 56, bottom: 168, child: _Star(size: 12, dim: true)),
        ],
      );
}

/// 계단으로 깎은 원. 칸 크기가 고정이라 어느 크기에서도 픽셀로 읽힌다.
class _PixelDisk extends CustomPainter {
  const _PixelDisk({
    required this.radius,
    required this.fill,
    this.outline = false,
    this.innerFill,
  });

  final double radius;
  final Color fill;
  final bool outline;
  final Color? innerFill;

  static const step = 4.0;

  static Path disk(Offset center, double r) {
    final halfRows = (r / step).ceil();
    final right = <Offset>[];
    final left = <Offset>[];
    for (var i = -halfRows; i < halfRows; i++) {
      final y = i * step;
      final midY = y + step / 2;
      final half =
          (math.sqrt(math.max(0, r * r - midY * midY)) / step + 0.5).floor() *
              step;
      if (half == 0) continue;
      right.addAll([center + Offset(half, y), center + Offset(half, y + step)]);
      left.addAll(
          [center + Offset(-half, y), center + Offset(-half, y + step)]);
    }
    return Path()..addPolygon([...right, ...left.reversed], true);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final plate = disk(center, size.width * radius);
    canvas.drawPath(
        plate.shift(AppPixelStyle.cardOffset),
        Paint()
          ..color = AppPixelStyle.shadow
          ..isAntiAlias = false);
    canvas.drawPath(
        plate,
        Paint()
          ..color = fill
          ..isAntiAlias = false);
    if (outline) {
      canvas.drawPath(
          plate,
          Paint()
            ..color = AppPixelStyle.outline
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..isAntiAlias = false);
    }
    final inner = innerFill;
    if (inner != null) {
      canvas.drawPath(
          disk(center, size.width * 0.372),
          Paint()
            ..color = inner
            ..isAntiAlias = false);
    }
  }

  @override
  bool shouldRepaint(_PixelDisk old) =>
      old.radius != radius || old.fill != fill || old.innerFill != innerFill;
}

/// 3안의 24시간 띠 — 루틴 블록이 박힌 하루.
class _DayRing extends CustomPainter {
  const _DayRing();

  static const _blocks = <(double, double, Color)>[
    (7 * 60, 60, RoutinePalette.amber),
    (9 * 60, 3 * 60, RoutinePalette.lavender),
    (13 * 60, 90, RoutinePalette.blue),
    (18 * 60, 60, RoutinePalette.green),
    (23 * 60, 60, RoutinePalette.violet),
  ];

  double _rad(double minutes) => minutes / 1440 * 2 * math.pi - math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.415;
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
        ..strokeWidth = size.width * 0.036
        ..strokeCap = StrokeCap.butt,
    );

    for (final (start, sweep, color) in _blocks) {
      canvas.drawArc(
        rect,
        _rad(start) + 0.05,
        sweep / 1440 * 2 * math.pi - 0.1,
        false,
        Paint()
          ..isAntiAlias = false
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.044
          ..strokeCap = StrokeCap.butt,
      );
    }
  }

  @override
  bool shouldRepaint(_DayRing old) => false;
}

/// 1안의 마크 — 픽셀에서 태어난 «하루 한 바퀴».
///
/// 두꺼운 계단 궤도 하나가 하루를 돈다. 그 위에 해와 달이 낮과 밤을 잡고,
/// 루틴 블록 두 개가 그날의 일정을 뜻한다. 26칸 격자라 48px 런처에서 한 칸이
/// 2px이 되어 아이콘으로 내려가도 형태가 남는다.
class _PixelDayMark extends CustomPainter {
  const _PixelDayMark();

  static const _navy = AppColors.textPrimary;
  static const _sun = RoutinePalette.amber;
  static const _moon = RoutinePalette.coral;

  static const _cells = 26;
  static const _sunDeg = 52.0;
  static const _moonDeg = 233.0;

  static double _rad(double deg) => (deg - 90) * math.pi / 180;

  Offset _at(Offset c, double r, double deg) =>
      Offset(c.dx + math.cos(_rad(deg)) * r, c.dy + math.sin(_rad(deg)) * r);

  void _cell(Canvas canvas, Offset at, double unit, Color color) {
    canvas.drawRect(
      Rect.fromLTWH((at.dx / unit).floorToDouble() * unit,
          (at.dy / unit).floorToDouble() * unit, unit, unit),
      Paint()
        ..color = color
        ..isAntiAlias = false,
    );
  }

  /// 도트 그림 한 장. 'X'가 칠하는 칸이다.
  void _sprite(
      Canvas canvas, Offset center, double unit, List<String> rows, Color c) {
    final h = rows.length;
    final w = rows.first.length;
    final origin = Offset(center.dx - w / 2 * unit, center.dy - h / 2 * unit);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (rows[y][x] != 'X') continue;
        _cell(canvas, origin + Offset(x * unit, y * unit), unit, c);
      }
    }
  }

  /// 궤도를 두 칸 두께로 찍는다.
  void _arc(Canvas canvas, Offset c, double unit, double radius, double from,
      double to, Color color) {
    for (var deg = from; deg <= to; deg += 0.7) {
      _cell(canvas, _at(c, radius, deg), unit, color);
      _cell(canvas, _at(c, radius - unit, deg), unit, color);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final unit = s / _cells;
    final center = Offset(s / 2, s / 2);
    final radius = s * 0.36;

    // 해와 달이 앉을 자리를 비운 두 개의 호.
    _arc(canvas, center, unit, radius, 74, 214, _navy);
    _arc(canvas, center, unit, radius, 252, 396, _navy);

    // 루틴 블록 — 궤도에 박힌 그날의 일정.
    _arc(canvas, center, unit, radius, 332, 350, RoutinePalette.lavender);
    _arc(canvas, center, unit, radius, 152, 170, RoutinePalette.green);

    // 해 — 5×5 도트 원.
    _sprite(
        canvas,
        _at(center, radius, _sunDeg),
        unit,
        const [
          '.XXX.',
          'XXXXX',
          'XXXXX',
          'XXXXX',
          '.XXX.',
        ],
        _sun);

    // 달 — 오른쪽이 열린 초승달.
    _sprite(
        canvas,
        _at(center, radius, _moonDeg),
        unit,
        const [
          '.XXX.',
          'XXX..',
          'XX...',
          'XXX..',
          '.XXX.',
        ],
        _moon);
  }

  @override
  bool shouldRepaint(_PixelDayMark old) => false;
}

class _Star extends StatelessWidget {
  const _Star({required this.size, this.dim = false});

  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _StarPainter(dim),
      );
}

class _StarPainter extends CustomPainter {
  const _StarPainter(this.dim);

  final bool dim;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 5;
    final paint = Paint()
      ..color = dim ? AppColors.decorationCloud : AppColors.orbitAccent
      ..isAntiAlias = false;
    canvas.drawRect(Rect.fromLTWH(unit * 2, 0, unit, size.height), paint);
    canvas.drawRect(Rect.fromLTWH(0, unit * 2, size.width, unit), paint);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.dim != dim;
}

class _Cloud extends StatelessWidget {
  const _Cloud({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(width, width * 0.5),
        painter: const _CloudPainter(),
      );
}

class _CloudPainter extends CustomPainter {
  const _CloudPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..addPolygon([
          Offset(0, size.height),
          Offset(0, size.height * .65),
          Offset(size.width * .18, size.height * .65),
          Offset(size.width * .18, size.height * .30),
          Offset(size.width * .35, size.height * .30),
          Offset(size.width * .35, 0),
          Offset(size.width * .58, 0),
          Offset(size.width * .58, size.height * .30),
          Offset(size.width * .76, size.height * .30),
          Offset(size.width * .76, size.height * .65),
          Offset(size.width, size.height * .65),
          Offset(size.width, size.height),
        ], true),
      Paint()
        ..color = AppColors.decorationCloud
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(_CloudPainter old) => false;
}

class _Moon extends StatelessWidget {
  const _Moon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: const _MoonPainter(),
      );
}

class _MoonPainter extends CustomPainter {
  const _MoonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawPath(
      Path()
        ..addPolygon([
          Offset(w * 0.38, 0),
          Offset(w * 0.72, 0),
          Offset(w * 0.72, h * 0.12),
          Offset(w * 0.56, h * 0.12),
          Offset(w * 0.56, h * 0.25),
          Offset(w * 0.47, h * 0.25),
          Offset(w * 0.47, h * 0.63),
          Offset(w * 0.56, h * 0.63),
          Offset(w * 0.56, h * 0.75),
          Offset(w * 0.72, h * 0.75),
          Offset(w * 0.72, h * 0.88),
          Offset(w * 0.91, h * 0.88),
          Offset(w * 0.91, h),
          Offset(w * 0.47, h),
          Offset(w * 0.47, h * 0.88),
          Offset(w * 0.25, h * 0.88),
          Offset(w * 0.25, h * 0.75),
          Offset(w * 0.13, h * 0.75),
          Offset(w * 0.13, h * 0.5),
          Offset(0, h * 0.5),
          Offset(0, h * 0.25),
          Offset(w * 0.13, h * 0.25),
          Offset(w * 0.13, h * 0.12),
          Offset(w * 0.38, h * 0.12),
        ], true),
      Paint()
        ..color = AppColors.orbitAccent
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(_MoonPainter old) => false;
}
