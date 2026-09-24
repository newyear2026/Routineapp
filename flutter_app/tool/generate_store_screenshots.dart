// App Store / Play 스토어용 마케팅 스크린샷.
//
// appscreens 템플릿처럼 큰 제목 + 폰 목업(또는 일러스트) 세로 카드다.
// 화면은 예시 데이터로 실제 위젯을 렌더링한다. 손으로 PNG를 그리지 않는다.
//
// 실행:
//   flutter test tool/generate_store_screenshots.dart
//
// 결과:
//   assets/store/screenshots/marketing/play/{ko,en,es}/*.png   1080×1920 (Play 9:16)
//   assets/store/screenshots/marketing/ios/{ko,en,es}/*.png    1290×2796 (App Store 6.7")
//   assets/store/screenshots/marketing/preview_{ko,en,es}.png  가로 스트립
//
// 위젯 테스트 하네스를 쓰는 이유는 generate_feature_graphic.dart 와 같다.
// 테스트 기본 폰트는 글자를 네모로 그리므로 Roboto·한글 폰트를 직접 올린다.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/models/routine_icon_id.dart';
import 'package:routine_timer/domain/models/routine_log.dart';
import 'package:routine_timer/domain/models/routine_log_status.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/l10n/app_localizations.dart';
import 'package:routine_timer/screens/home_screen.dart';
import 'package:routine_timer/screens/routine_add_screen.dart';
import 'package:routine_timer/screens/routines_screen.dart';
import 'package:routine_timer/screens/today_progress_screen.dart';
import 'package:routine_timer/theme/app_colors.dart';
import 'package:routine_timer/theme/app_theme.dart';
import 'package:routine_timer/theme/routine_palette.dart';
import 'package:routine_timer/widget_medium/home_medium_widget.dart';
import 'package:routine_timer/widget_medium/home_medium_widget_view_model.dart';
import 'package:routine_timer/widgets/ds/animated_cat.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/support/test_doubles.dart';

const _logicalW = 390.0;
const _logicalH = 844.0;
const _capturePixelRatio = 3.0;
const _now = '15:14';
final _shotDate = DateTime(2026, 9, 8, 15, 14);

const _play = _CanvasSpec(
  folder: 'play',
  width: 1080,
  height: 1920,
  sidePad: 56,
  titleTop: 64,
  titleSize: 58,
  phoneWidth: 736,
  phoneTop: 248,
);

const _ios = _CanvasSpec(
  folder: 'ios',
  width: 1290,
  height: 2796,
  sidePad: 72,
  titleTop: 120,
  titleSize: 64,
  phoneWidth: 980,
  phoneTop: 460,
);

void main() {
  testWidgets('appscreens 스타일 스토어 스크린샷을 뽑는다', (tester) async {
    await initializeDateFormatting();
    await _loadFonts();
    final brandIcon = await tester.runAsync(_loadBrandIcon);
    final catGuide = await tester.runAsync(
      () => _loadAssetPng(
        'assets/characters/cat_starlight/v1/approved/guide.png',
        targetWidth: 560,
      ),
    );
    addTearDown(brandIcon!.dispose);
    addTearDown(catGuide!.dispose);

    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('home_widget');
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => true);
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));

    for (final locale in const [
      Locale('ko'),
      Locale('en'),
      Locale('es'),
    ]) {
      final l10n = lookupAppLocalizations(locale);
      final app = await _controllerFor(l10n);
      addTearDown(app.dispose);

      final shots = <String, ui.Image>{};
      Future<void> take(
        String name,
        Widget screen, {
        Future<void> Function(WidgetTester tester)? afterPump,
      }) async {
        shots[name] = await _captureScreen(
          tester,
          locale: locale,
          screen: screen,
          app: app,
          afterPump: afterPump,
        );
      }

      await take('home', const HomeScreen());
      await take('progress', const TodayProgressScreen());
      await take('routines', const RoutinesScreen());
      await take(
        'calendar',
        const RoutinesScreen(),
        afterPump: (tester) async {
          await tester.tap(find.text(l10n.routinesViewCalendar));
          await tester.pump();
        },
      );
      await take(
        'add',
        const RoutineAddScreen(),
        afterPump: (tester) async {
          await tester.tap(find.text(l10n.routineQuickReading), warnIfMissed: false);
          await tester.pump();
        },
      );
      shots['widget'] = await _captureScreen(
        tester,
        locale: locale,
        screen: _GlanceScreen(
          l10n: l10n,
          icon: brandIcon,
          bodyFamily:
              locale.languageCode == 'ko' ? 'ScreenshotKo' : 'ScreenshotBody',
        ),
      );

      final copy = _Copy.of(locale);
      final slides = <_Slide>[
        _Slide(
          file: '01_home',
          lines: copy.home,
          accentLine: 1,
          theme: _SlideTheme.purple,
          screen: shots['home'],
        ),
        _Slide(
          file: '02_progress',
          lines: copy.progress,
          accentLine: 1,
          theme: _SlideTheme.green,
          screen: shots['progress'],
        ),
        _Slide(
          file: '03_widget',
          lines: copy.widget,
          accentLine: 1,
          theme: _SlideTheme.blue,
          screen: shots['widget'],
          lightStatus: true,
        ),
        _Slide(
          file: '04_routines',
          lines: copy.routines,
          accentLine: 1,
          theme: _SlideTheme.magenta,
          screen: shots['routines'],
        ),
        _Slide(
          file: '05_add',
          lines: copy.add,
          accentLine: 1,
          theme: _SlideTheme.amber,
          screen: shots['add'],
        ),
        _Slide(
          file: '06_calendar',
          lines: copy.calendar,
          accentLine: 1,
          theme: _SlideTheme.violet,
          screen: shots['calendar'],
        ),
        _Slide(
          file: '07_start',
          lines: copy.cta,
          accentLine: 1,
          theme: _SlideTheme.gold,
          subtitle: copy.ctaSub,
          art: _CtaArt(
            icon: brandIcon,
            cat: catGuide,
            titleFamily: locale.languageCode == 'ko'
                ? 'ScreenshotKoBold'
                : 'ScreenshotTitle',
          ),
        ),
      ];

      final playPaths = <String>[];
      for (final spec in [_play, _ios]) {
        for (final slide in slides) {
          final path = await _compose(
            tester,
            spec: spec,
            locale: locale,
            slide: slide,
          );
          if (spec.folder == 'play') playPaths.add(path);
        }
      }

      await _writeStrip(
        tester,
        locale: locale,
        paths: playPaths,
      );

      for (final image in shots.values) {
        image.dispose();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 8)));
}

class _CanvasSpec {
  const _CanvasSpec({
    required this.folder,
    required this.width,
    required this.height,
    required this.sidePad,
    required this.titleTop,
    required this.titleSize,
    required this.phoneWidth,
    required this.phoneTop,
  });

  final String folder;
  final double width;
  final double height;
  final double sidePad;
  final double titleTop;
  final double titleSize;
  final double phoneWidth;
  final double phoneTop;
}

class _SlideTheme {
  const _SlideTheme({
    required this.top,
    required this.bottom,
    required this.accent,
  });

  final Color top;
  final Color bottom;
  final Color accent;

  static const purple = _SlideTheme(
    top: Color(0xFF16122E),
    bottom: Color(0xFF3D2A7A),
    accent: Color(0xFFC4B5FD),
  );
  static const green = _SlideTheme(
    top: Color(0xFF10241C),
    bottom: Color(0xFF1F6B45),
    accent: Color(0xFF7FDD8F),
  );
  static const blue = _SlideTheme(
    top: Color(0xFF10182C),
    bottom: Color(0xFF2A4F9A),
    accent: Color(0xFF7EC8F8),
  );
  static const magenta = _SlideTheme(
    top: Color(0xFF24122A),
    bottom: Color(0xFF7A3FA8),
    accent: Color(0xFFE2A8F8),
  );
  static const amber = _SlideTheme(
    top: Color(0xFF2A1A10),
    bottom: Color(0xFFB56A1E),
    accent: Color(0xFFFFAD3D),
  );
  static const violet = _SlideTheme(
    top: Color(0xFF181230),
    bottom: Color(0xFF5A4AD0),
    accent: Color(0xFFB7A6FF),
  );
  static const gold = _SlideTheme(
    top: Color(0xFF1A1430),
    bottom: Color(0xFFC4782A),
    accent: Color(0xFFFFE08A),
  );
}

class _Slide {
  const _Slide({
    required this.file,
    required this.lines,
    required this.theme,
    this.accentLine = 1,
    this.subtitle,
    this.screen,
    this.art,
    this.lightStatus = false,
  });

  final String file;
  final List<String> lines;
  final int accentLine;
  final _SlideTheme theme;
  final String? subtitle;
  final ui.Image? screen;
  final Widget? art;
  final bool lightStatus;
}

class _Copy {
  const _Copy({
    required this.home,
    required this.progress,
    required this.widget,
    required this.routines,
    required this.add,
    required this.calendar,
    required this.cta,
    required this.ctaSub,
  });

  final List<String> home;
  final List<String> progress;
  final List<String> widget;
  final List<String> routines;
  final List<String> add;
  final List<String> calendar;
  final List<String> cta;
  final String ctaSub;

  static _Copy of(Locale locale) => switch (locale.languageCode) {
        'ko' => const _Copy(
            home: ['하루를', '원 하나로'],
            progress: ['오늘 어디까지', '왔는지'],
            widget: ['앱을 열지', '않아도'],
            routines: ['하루가 색으로', '채워진다'],
            add: ['루틴을', '바로 만든다'],
            calendar: ['한 달의 리듬이', '한눈에'],
            cta: ['계정 없이', '바로 시작'],
            ctaSub: '회원가입 없음 · 오프라인 · 기기에만 저장',
          ),
        'es' => const _Copy(
            home: ['Tu día', 'en un círculo'],
            progress: ['Ve el progreso', 'cada día'],
            widget: ['Tu día', 'de un vistazo'],
            routines: ['Un día', 'en color'],
            add: ['Crea tu ritmo', 'al momento'],
            calendar: ['Un mes de ritmo,', 'de un vistazo'],
            cta: ['Sin cuenta.', 'Empieza ya.'],
            ctaSub: 'Sin registro · sin conexión · solo en tu dispositivo',
          ),
        _ => const _Copy(
            home: ['Your day', 'as one circle'],
            progress: ['See progress', 'every day'],
            widget: ['Your day', 'at a glance'],
            routines: ['A day', 'in color'],
            add: ['Make a routine', 'in a moment'],
            calendar: ['A month of rhythm,', 'at a glance'],
            cta: ['No account.', 'Just start.'],
            ctaSub: 'No sign-up · works offline · stays on your device',
          ),
      };
}

Future<RoutineAppController> _controllerFor(AppLocalizations l10n) async {
  final logs = MemoryLogRepository();
  const ymd = '2026-09-08';
  for (final id in ['wake', 'exercise', 'breakfast', 'study', 'lunch']) {
    logs.logs.add(RoutineLog(
      id: 'log_$id',
      routineId: id,
      dateYmd: ymd,
      status: RoutineLogStatus.completed,
      completedAtMs: DateTime(2026, 9, 8, 8).millisecondsSinceEpoch,
    ));
  }
  final app = RoutineAppController(
    dataService: RoutineDataService(
      routineRepository: MemoryRoutineRepository(_demoRoutines(l10n)),
      logRepository: logs,
    ),
    notificationService: RoutineNotificationService(
      exactAlarmsAllowed: () async => false,
      gateway: NoopNotificationGateway(),
      preferencesLoader: () async => NotificationPreferences.firstLaunchDefaults,
    ),
    nowProvider: () => _shotDate,
    clockAutoRefreshEnabled: false,
  );
  await app.load();
  return app;
}

List<Routine> _demoRoutines(AppLocalizations l10n) {
  Routine item({
    required String id,
    required String title,
    required int startHour,
    required int endHour,
    required int color,
    required RoutineIconId icon,
  }) {
    return Routine(
      id: id,
      title: title,
      startMinutesFromMidnight: startHour * 60,
      endMinutesFromMidnight: endHour * 60,
      repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      colorValue: color,
      iconEmoji: '',
      iconId: icon,
      updatedAtMs: 1,
    );
  }

  return [
    item(
      id: 'wake',
      title: l10n.catalogWakeUp,
      startHour: 7,
      endHour: 8,
      color: RoutinePalette.coralValue,
      icon: RoutineIconId.sun,
    ),
    item(
      id: 'exercise',
      title: l10n.catalogExercise,
      startHour: 8,
      endHour: 9,
      color: RoutinePalette.roseValue,
      icon: RoutineIconId.dumbbell,
    ),
    item(
      id: 'breakfast',
      title: l10n.catalogBreakfast,
      startHour: 9,
      endHour: 10,
      color: RoutinePalette.amberValue,
      icon: RoutineIconId.breakfast,
    ),
    item(
      id: 'study',
      title: l10n.catalogStudy,
      startHour: 10,
      endHour: 12,
      color: RoutinePalette.lavenderValue,
      icon: RoutineIconId.book,
    ),
    item(
      id: 'lunch',
      title: l10n.catalogLunch,
      startHour: 12,
      endHour: 13,
      color: RoutinePalette.orangeValue,
      icon: RoutineIconId.bowl,
    ),
    item(
      id: 'rest',
      title: l10n.catalogBreak,
      startHour: 15,
      endHour: 16,
      color: RoutinePalette.blueValue,
      icon: RoutineIconId.coffee,
    ),
    item(
      id: 'dinner',
      title: l10n.catalogDinner,
      startHour: 18,
      endHour: 19,
      color: RoutinePalette.greenValue,
      icon: RoutineIconId.utensils,
    ),
    item(
      id: 'sleep',
      title: l10n.catalogSleep,
      startHour: 23,
      endHour: 24,
      color: RoutinePalette.violetValue,
      icon: RoutineIconId.moon,
    ),
  ];
}

Future<ui.Image> _captureScreen(
  WidgetTester tester, {
  required Locale locale,
  required Widget screen,
  RoutineAppController? app,
  Future<void> Function(WidgetTester tester)? afterPump,
}) async {
  tester.view
    ..physicalSize = const Size(_logicalW, _logicalH)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  final fontFamily = locale.languageCode == 'ko' ? 'ScreenshotKo' : 'Roboto';
  Widget child = MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildRoutineTheme(fontFamily: fontFamily),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: TickerMode(enabled: false, child: child!),
    ),
    home: RepaintBoundary(key: key, child: screen),
  );
  if (app != null) {
    child = ChangeNotifierProvider.value(value: app, child: child);
  }

  await tester.pumpWidget(child);
  await tester.runAsync(() async {
    final context = key.currentContext;
    if (context != null) await _precache(context);
  });
  await tester.pump();
  if (afterPump != null) await afterPump(tester);
  await tester.pump();
  expect(tester.takeException(), isNull);

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await tester.runAsync(
    () => boundary.toImage(pixelRatio: _capturePixelRatio),
  );
  return image!;
}

Future<String> _compose(
  WidgetTester tester, {
  required _CanvasSpec spec,
  required Locale locale,
  required _Slide slide,
}) async {
  tester.view
    ..physicalSize = Size(spec.width, spec.height)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  final titleFamily =
      locale.languageCode == 'ko' ? 'ScreenshotKoBold' : 'ScreenshotTitle';
  final bodyFamily =
      locale.languageCode == 'ko' ? 'ScreenshotKo' : 'ScreenshotBody';

  await tester.pumpWidget(
    Directionality(
      textDirection: ui.TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: SizedBox(
          width: spec.width,
          height: spec.height,
          child: _MarketingCard(
            spec: spec,
            slide: slide,
            titleFamily: titleFamily,
            bodyFamily: bodyFamily,
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });

  final file = File(
    'assets/store/screenshots/marketing/${spec.folder}/${locale.languageCode}/${slide.file}.png',
  );
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!);
  // ignore: avoid_print
  print('wrote ${file.path}');
  return file.path;
}

Future<void> _writeStrip(
  WidgetTester tester, {
  required Locale locale,
  required List<String> paths,
}) async {
  const cardW = 270.0;
  const cardH = 480.0;
  const gap = 14.0;
  const pad = 40.0;
  final width = pad * 2 + paths.length * cardW + (paths.length - 1) * gap;
  const height = 40 + 36 + 16 + cardH + 40;

  final images = <ui.Image>[];
  for (final path in paths) {
    final codec = await tester.runAsync(
      () => ui.instantiateImageCodec(File(path).readAsBytesSync()),
    );
    final frame = await tester.runAsync(() => codec!.getNextFrame());
    images.add(frame!.image);
    codec!.dispose();
  }

  tester.view
    ..physicalSize = Size(width, height)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: ui.TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: ColoredBox(
          color: const Color(0xFFF7F4EE),
          child: SizedBox(
            width: width,
            height: height,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(pad, 40, pad, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LOOPET',
                    style: TextStyle(
                      fontFamily: 'ScreenshotTitle',
                      fontSize: 28,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      children: [
                        for (var i = 0; i < images.length; i++) ...[
                          if (i > 0) const SizedBox(width: gap),
                          SizedBox(
                            width: cardW,
                            height: cardH,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: RawImage(
                                image: images[i],
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.medium,
                              ),
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
        ),
      ),
    ),
  );
  await tester.pump();

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  final file = File(
    'assets/store/screenshots/marketing/preview_${locale.languageCode}.png',
  );
  file.writeAsBytesSync(bytes!);
  for (final image in images) {
    image.dispose();
  }
  // ignore: avoid_print
  print('wrote ${file.path}');
}

class _MarketingCard extends StatelessWidget {
  const _MarketingCard({
    required this.spec,
    required this.slide,
    required this.titleFamily,
    required this.bodyFamily,
  });

  final _CanvasSpec spec;
  final _Slide slide;
  final String titleFamily;
  final String bodyFamily;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [slide.theme.top, slide.theme.bottom],
            ),
          ),
        ),
        const CustomPaint(painter: _StarFieldPainter()),
        Padding(
          padding: EdgeInsets.fromLTRB(spec.sidePad, spec.titleTop, spec.sidePad, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < slide.lines.length; i++)
                Text(
                  slide.lines[i],
                  style: TextStyle(
                    fontFamily: titleFamily,
                    fontSize: spec.titleSize,
                    height: 1.08,
                    letterSpacing: -1.2,
                    color: i == slide.accentLine
                        ? slide.theme.accent
                        : const Color(0xFFF8F4EC),
                  ),
                ),
              if (slide.subtitle != null) ...[
                const SizedBox(height: 18),
                Text(
                  slide.subtitle!,
                  style: TextStyle(
                    fontFamily: bodyFamily,
                    fontSize: spec.titleSize * 0.34,
                    height: 1.35,
                    color: const Color(0xCCF8F4EC),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (slide.screen != null)
          Positioned(
            top: spec.phoneTop,
            left: (spec.width - spec.phoneWidth) / 2,
            width: spec.phoneWidth,
            child: _PhoneChrome(
              screen: slide.screen!,
              width: spec.phoneWidth,
              lightStatus: slide.lightStatus,
            ),
          ),
        if (slide.art != null)
          Positioned(
            left: 0,
            right: 0,
            top: spec.phoneTop * 0.92,
            bottom: 0,
            child: slide.art!,
          ),
      ],
    );
  }
}

class _PhoneChrome extends StatelessWidget {
  const _PhoneChrome({
    required this.screen,
    required this.width,
    required this.lightStatus,
  });

  final ui.Image screen;
  final double width;
  final bool lightStatus;

  @override
  Widget build(BuildContext context) {
    const bezel = 14.0;
    const islandW = 118.0;
    const islandH = 34.0;
    final screenW = width - bezel * 2;
    final screenH = screenW * (_logicalH / _logicalW);
    final height = screenH + bezel * 2;
    final radius = width * 0.14;
    final innerRadius = radius - 8;
    final statusColor =
        lightStatus ? const Color(0xF5FFFFFF) : const Color(0xF0221C42);
    final indicatorColor =
        lightStatus ? const Color(0xE6FFFFFF) : const Color(0xE0221C42);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0C0B10),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 48,
            offset: Offset(0, 28),
          ),
        ],
        border: Border.all(color: const Color(0xFF2A2833), width: 2),
      ),
      padding: const EdgeInsets.all(bezel),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            RawImage(
              image: screen,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 44,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 18, 0),
                child: Row(
                  children: [
                    Text(
                      _now,
                      style: TextStyle(
                        fontFamily: 'ScreenshotBody',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    const Spacer(),
                    CustomPaint(
                      size: const Size(62, 12),
                      painter: _StatusIconsPainter(color: statusColor),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: (screenW - islandW) / 2,
              child: Container(
                width: islandW,
                height: islandH,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0B10),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Positioned(
              left: (screenW - 126) / 2,
              bottom: 8,
              child: Container(
                width: 126,
                height: 5,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIconsPainter extends CustomPainter {
  const _StatusIconsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    var x = 0.0;
    for (var i = 0; i < 4; i++) {
      final h = 4.0 + i * 2.2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h, 3, h),
          const Radius.circular(0.6),
        ),
        paint,
      );
      x += 5;
    }
    x += 6;
    canvas.drawCircle(Offset(x + 5, size.height / 2), 5, paint..style = PaintingStyle.stroke..strokeWidth = 1.6);
    canvas.drawCircle(Offset(x + 5, size.height / 2), 1.4, Paint()..color = color);
    x += 18;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 2, 22, size.height - 4),
        const Radius.circular(3),
      ),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 2, 4, 14, size.height - 8),
        const Radius.circular(1.5),
      ),
      Paint()..color = color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 22, size.height / 2 - 2, 2, 4),
        const Radius.circular(0.6),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _StatusIconsPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x33F8F4EC);
    const cells = [
      Offset(0.08, 0.22),
      Offset(0.92, 0.18),
      Offset(0.14, 0.58),
      Offset(0.88, 0.62),
      Offset(0.06, 0.84),
      Offset(0.94, 0.78),
      Offset(0.22, 0.12),
      Offset(0.78, 0.28),
    ];
    for (final cell in cells) {
      final c = Offset(cell.dx * size.width, cell.dy * size.height);
      final s = 5.0 + (cell.dx + cell.dy) * 4;
      _plus(canvas, c, s, paint);
    }
  }

  void _plus(Canvas canvas, Offset c, double s, Paint paint) {
    final t = math.max(1.6, s * 0.22);
    canvas.drawRect(Rect.fromCenter(center: c, width: s, height: t), paint);
    canvas.drawRect(Rect.fromCenter(center: c, width: t, height: s), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CtaArt extends StatelessWidget {
  const _CtaArt({
    required this.icon,
    required this.cat,
    required this.titleFamily,
  });

  final ui.Image icon;
  final ui.Image cat;
  final String titleFamily;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final catSize = math.min(box.maxWidth * 0.78, box.maxHeight * 0.56);
        final iconSize = math.min(200.0, catSize * 0.46);
        return Column(
          children: [
            const Spacer(flex: 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(iconSize * 0.22),
              child: RawImage(
                image: icon,
                width: iconSize,
                height: iconSize,
                filterQuality: FilterQuality.none,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'LOOPET',
              style: TextStyle(
                fontFamily: titleFamily,
                fontSize: 42,
                letterSpacing: -1.2,
                color: const Color(0xFFF8F4EC),
              ),
            ),
            const Spacer(),
            RawImage(
              image: cat,
              width: catSize,
              height: catSize,
              filterQuality: FilterQuality.none,
            ),
            SizedBox(height: box.maxHeight * 0.05),
          ],
        );
      },
    );
  }
}

class _GlanceScreen extends StatelessWidget {
  const _GlanceScreen({
    required this.l10n,
    required this.icon,
    required this.bodyFamily,
  });

  final AppLocalizations l10n;
  final ui.Image icon;
  final String bodyFamily;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.MMMMEEEEd(locale).format(_shotDate);
    return ColoredBox(
      color: const Color(0xFF1B1840),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A2458), Color(0xFF6744F4), Color(0xFF1B1840)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 56, 18, 22),
          child: SelectionContainer.disabled(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontFamily: bodyFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xF2FFFFFF),
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  _now,
                  style: const TextStyle(
                    fontFamily: 'PixelifySans',
                    fontSize: 72,
                    height: 1.0,
                    color: Color(0xFFF8F4EC),
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 22),
                HomeMediumWidget(
                  viewModel: HomeMediumWidgetViewModel.dummy(l10n),
                  ringSize: 96,
                ),
                const Spacer(),
                Center(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
                    decoration: BoxDecoration(
                      color: const Color(0x55FFFFFF),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: RawImage(
                            image: icon,
                            width: 62,
                            height: 62,
                            filterQuality: FilterQuality.none,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.appName,
                          style: TextStyle(
                            fontFamily: bodyFamily,
                            fontSize: 12,
                            color: const Color(0xF2FFFFFF),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _precache(BuildContext context) async {
  for (final icon in RoutineIconId.values) {
    await precacheImage(
      AssetImage('assets/routine_icons/${icon.name}.png'),
      context,
    );
  }
  for (final pose in CatPose.values) {
    await precacheImage(
      AssetImage(CharacterPackCatalog.defaultPack.assetFor(pose.name)!),
      context,
    );
  }
  for (final asset in ['plant', 'bell', 'sleeping-cat']) {
    await precacheImage(AssetImage('assets/decorations/$asset.png'), context);
  }
}

Future<ui.Image> _loadBrandIcon() =>
    _loadAssetPng('assets/icon/app_icon.png', targetWidth: 512);

Future<ui.Image> _loadAssetPng(String path, {int? targetWidth}) async {
  final codec = await ui.instantiateImageCodec(
    File(path).readAsBytesSync(),
    targetWidth: targetWidth,
  );
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}

Future<void> _loadFonts() async {
  Directory? dir;
  for (var d = File(Platform.resolvedExecutable).parent;
      d.path != d.parent.path;
      d = d.parent) {
    final candidate = Directory('${d.path}/artifacts/material_fonts');
    if (candidate.existsSync()) {
      dir = candidate;
      break;
    }
  }
  if (dir == null) {
    throw StateError('Roboto를 찾지 못했다 (Flutter 캐시의 material_fonts)');
  }
  for (final entry in {
    'Roboto': 'Roboto-Regular.ttf',
    'ScreenshotBody': 'Roboto-Medium.ttf',
    'ScreenshotTitle': 'Roboto-Black.ttf',
    'Ahem': 'Roboto-Regular.ttf',
    'MaterialIcons': 'MaterialIcons-Regular.otf',
  }.entries) {
    final file = File('${dir.path}/${entry.value}');
    final loader = FontLoader(entry.key)
      ..addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
    await loader.load();
  }

  final pixel = FontLoader('PixelifySans')
    ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
  await pixel.load();

  const extraBold = '/tmp/dayround-AppleSDGothicNeo-ExtraBold.ttf';
  const medium = '/tmp/dayround-AppleSDGothicNeo-Medium.ttf';
  if (!File(extraBold).existsSync() || !File(medium).existsSync()) {
    final result = await Process.run('python3', [
      '-c',
      'from fontTools.ttLib.ttCollection import TTCollection\n'
          'c = TTCollection("/System/Library/Fonts/AppleSDGothicNeo.ttc")\n'
          'c.fonts[14].save("$extraBold")\n'
          'c.fonts[2].save("$medium")\n',
    ]);
    if (result.exitCode != 0) {
      throw StateError('한글 폰트를 추출하지 못했다: ${result.stderr}');
    }
  }
  for (final entry in {
    'ScreenshotKoBold': extraBold,
    'ScreenshotKo': medium,
  }.entries) {
    final loader = FontLoader(entry.key)
      ..addFont(
        Future.value(ByteData.view(File(entry.value).readAsBytesSync().buffer)),
      );
    await loader.load();
  }
}
