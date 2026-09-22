import 'package:routine_timer/screens/notification_permission_screen.dart';
import 'package:routine_timer/screens/today_progress_screen.dart';
import 'package:routine_timer/screens/onboarding_screen.dart';
import 'package:routine_timer/screens/widget_medium_preview_screen.dart';
// 실제 HomeScreen을 예시 데이터로 렌더링한다. 앱 저장소는 변경하지 않는다.
// flutter test tool/render_pixel_home.dart --dart-define=PREVIEW_FONT=/path/to/korean.ttf
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/screens/home_screen.dart';
import 'package:routine_timer/screens/routines_screen.dart';
import 'package:routine_timer/screens/routine_add_screen.dart';
import 'package:routine_timer/screens/settings_screen.dart';
import 'package:routine_timer/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../test/support/test_doubles.dart';
import '../test/support/localization.dart';

void main() {
  testWidgets('실제 홈 화면의 픽셀 스타일 미리보기', (tester) async {
    await initializeDateFormatting();
    const fontPath = String.fromEnvironment('PREVIEW_FONT');
    if (fontPath.isEmpty) throw StateError('PREVIEW_FONT에 로컬 한글 폰트를 지정하세요.');
    final font = FontLoader('PreviewKorean')
      ..addFont(
          Future.value(ByteData.sublistView(File(fontPath).readAsBytesSync())));
    await font.load();
    final numbers = FontLoader('PixelifySans')
      ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
    await numbers.load();
    Directory? materialFonts;
    for (var d = File(Platform.resolvedExecutable).parent;
        d.path != d.parent.path;
        d = d.parent) {
      final candidate = Directory('${d.path}/artifacts/material_fonts');
      if (candidate.existsSync()) {
        materialFonts = candidate;
        break;
      }
    }
    if (materialFonts == null) {
      throw StateError('Flutter material_fonts 캐시가 필요합니다.');
    }
    for (final entry in {
      'MaterialIcons': 'MaterialIcons-Regular.otf',
      'Ahem': 'Roboto-Regular.ttf'
    }.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(Future.value(ByteData.sublistView(
            File('${materialFonts.path}/${entry.value}').readAsBytesSync())));
      await loader.load();
    }
    // 이 도구는 flutter test로만 실행하는 렌더링 하네스다.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('home_widget');
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => true);
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: MemoryRoutineRepository([
          dailyRoutine(
              id: 'wake',
              title: '기상',
              startHour: 7,
              endHour: 8,
              colorValue: 0xFFFFAD3D),
          dailyRoutine(id: 'focus', title: '집중', startHour: 9, endHour: 12),
          dailyRoutine(
              id: 'rest',
              title: '휴식',
              startHour: 15,
              endHour: 16,
              colorValue: 0xFF56B7E8),
          dailyRoutine(
              id: 'dinner',
              title: '저녁 식사',
              startHour: 18,
              endHour: 19,
              colorValue: 0xFF59C58A),
          dailyRoutine(id: 'sleep', title: '취침', startHour: 23, endHour: 24),
        ]),
        logRepository: MemoryLogRepository(),
      ),
      notificationService: RoutineNotificationService(
        exactAlarmsAllowed: () async => false,
        gateway: NoopNotificationGateway(),
        preferencesLoader: () async =>
            NotificationPreferences.firstLaunchDefaults,
      ),
      nowProvider: () => DateTime(2026, 9, 8, 15, 14),
      clockAutoRefreshEnabled: false,
    );
    await app.load();
    final key = GlobalKey();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: app,
      child: localizedApp(
          home: Theme(
        data: buildRoutineTheme(fontFamily: 'PreviewKorean'),
        child: RepaintBoundary(key: key, child: const HomeScreen()),
      )),
    ));
    // 이미지 디코딩은 실제 비동기 작업이므로 완료 후 화면을 캡처한다.
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/decorations/home-sky.png'),
        key.currentContext!,
      );
      for (final asset in ['plant', 'bell', 'sleeping-cat']) {
        await precacheImage(
            ResizeImage(AssetImage('assets/decorations/$asset.png'),
                width: 256),
            key.currentContext!);
      }
      for (final pose in [
        'idle',
        'activity',
        'focus',
        'complete',
        'rest',
        'guide'
      ]) {
        await precacheImage(
          ResizeImage(
            AssetImage('assets/characters/cat_starlight/v1/approved/$pose.png'),
            width: 384,
          ),
          key.currentContext!,
        );
      }
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final image in tester.widgetList<RawImage>(find.byType(RawImage))) {
      expect(image.image, isNotNull);
    }
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    final out = File('output/pixel-preview/home.png');
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(bytes!);
    // 공통 컨트롤이 쓰이는 실제 화면도 같은 테마로 확인한다.
    tester.view.physicalSize = const Size(390, 844);
    for (final page in <String, Widget>{
      'routines': const RoutinesScreen(),
      'routine-add': const RoutineAddScreen(),
      'routine-edit': const RoutineAddScreen(editRoutineId: 'focus'),
      'settings': const SettingsScreen(),
      'progress': const TodayProgressScreen(),
      'notification-permission': const NotificationPermissionScreen(),
      'onboarding': const OnboardingScreen(),
      'widget-preview': const WidgetMediumPreviewScreen(),
    }.entries) {
      final pageKey = GlobalKey();
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: app,
        child: localizedApp(
            home: Theme(
          data: buildRoutineTheme(fontFamily: 'PreviewKorean'),
          child: RepaintBoundary(key: pageKey, child: page.value),
        )),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _capture(tester, pageKey, page.key);
      if (page.key == 'onboarding') {
        for (var step = 2; step <= 3; step++) {
          await tester.tap(find.byKey(const Key('onboarding-next-button')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await _capture(tester, pageKey, 'onboarding-$step');
        }
      }
      if (page.key == 'routines') {
        await tester.tap(find.text(testL10n.routinesViewCalendar));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _capture(tester, pageKey, 'calendar');
      }
    }
    // 작은 화면 / 큰 글씨에서도 레이아웃이 깨지지 않는지 확인한다.
    tester.view.physicalSize = const Size(320, 700);
    for (final screen in <Widget>[
      const HomeScreen(),
      const RoutineAddScreen(),
      const RoutineAddScreen(editRoutineId: 'focus'),
      const TodayProgressScreen(),
      const OnboardingScreen(),
      const WidgetMediumPreviewScreen(),
    ]) {
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: app,
        child: localizedApp(
            home: MediaQuery(
          data: const MediaQueryData(
              size: Size(320, 700), textScaler: TextScaler.linear(1.5)),
          child: screen,
        )),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  File('output/pixel-preview/$name.png').writeAsBytesSync(bytes!);
}
