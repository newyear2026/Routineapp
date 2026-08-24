import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/l10n/app_localizations.dart';
import 'package:routine_timer/screens/routine_add/routine_form_controls.dart';
import 'package:routine_timer/screens/routine_add_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_doubles.dart';

/// 루틴 추가 화면의 시각 선택기 — 언어를 바꿔도 열리고 값을 돌려줘야 한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const homeWidgetChannel = MethodChannel('home_widget');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, (call) async => true);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, null);
  });

  Future<RoutineAppController> pumpAddScreen(
    WidgetTester tester,
    Locale locale, {
    Size size = const Size(390, 844),
    double textScale = 1.0,
    bool? alwaysUse24HourFormat,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: MemoryRoutineRepository(const []),
        logRepository: MemoryLogRepository(),
      ),
      notificationService: RoutineNotificationService(
        gateway: NoopNotificationGateway(),
        preferencesLoader: () async =>
            NotificationPreferences.firstLaunchDefaults,
      ),
      nowProvider: () => DateTime(2026, 8, 24, 10, 0),
      clockAutoRefreshEnabled: false,
    );
    await controller.load();
    addTearDown(controller.dispose);

    final router = GoRouter(
      initialLocation: '/routine-add',
      routes: [
        GoRoute(
          path: '/routine-add',
          builder: (context, state) => const RoutineAddScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: MaterialApp.router(
          routerConfig: router,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              alwaysUse24HourFormat: alwaysUse24HourFormat,
            ),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  /// 폼은 스크롤된다 — 라틴 문자에서는 시각 타일이 저장 바 아래로 내려간다.
  /// 실제 사용자도 스크롤해서 누르므로, 테스트도 먼저 보이게 만든다.
  Future<void> tapTile(WidgetTester tester, String label) async {
    final tile = find.text(label);
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
  }

  for (final locale in const [Locale('ko'), Locale('en'), Locale('es')]) {
    final code = locale.languageCode;

    testWidgets('$code — 시작 시간 타일을 누르면 원형 선택기가 열린다', (tester) async {
      await pumpAddScreen(tester, locale);
      final l10n = lookupAppLocalizations(locale);

      await tapTile(tester, l10n.routineAddStartTime);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('orbit-time-picker-confirm')), findsOneWidget);
      // 세 언어 모두 같은 화면을 본다 — Material 선택기처럼 로케일에 따라
      // 12시간/24시간으로 갈리지 않는다.
      expect(find.byType(TimePickerDialog), findsNothing);
    });

    testWidgets('$code — 시 링은 24칸이고 라벨이 서로 겹치지 않는다', (tester) async {
      await pumpAddScreen(tester, locale);
      final l10n = lookupAppLocalizations(locale);

      await tapTile(tester, l10n.routineAddStartTime);

      // 00~23이 모두 보인다. Material 기본 선택기는 이걸 두 겹으로 그려서
      // 좁은 화면에서 숫자가 서로 겹쳤다.
      final centers = <String, Offset>{};
      for (var h = 0; h < 24; h++) {
        final label = h.toString().padLeft(2, '0');
        final finder = find.descendant(
          of: find.byKey(const Key('orbit-time-picker-dial')),
          matching: find.text(label),
        );
        expect(finder, findsOneWidget, reason: '$label 라벨이 없다');
        centers[label] = tester.getCenter(finder);
      }

      // 이웃한 두 라벨의 거리가 글자 크기보다 넉넉해야 읽을 수 있다.
      final labels = centers.keys.toList();
      for (var i = 0; i < labels.length; i++) {
        for (var j = i + 1; j < labels.length; j++) {
          final distance = (centers[labels[i]]! - centers[labels[j]]!).distance;
          expect(distance, greaterThan(24),
              reason: '${labels[i]}와 ${labels[j]}가 겹친다 '
                  '— 거리 ${distance.toStringAsFixed(1)}');
        }
      }
    });

    testWidgets('$code — 시를 고르면 분 선택으로 넘어간다', (tester) async {
      await pumpAddScreen(tester, locale);
      final l10n = lookupAppLocalizations(locale);

      await tapTile(tester, l10n.routineAddStartTime);

      final dial = find.byKey(const Key('orbit-time-picker-dial'));
      final radius = tester.getSize(dial).width / 2;
      final center = tester.getCenter(dial);

      // 시 링에는 23이 있고 분 링에는 없다 — 무엇을 고르는 중인지 이걸로 안다.
      expect(
        find.descendant(of: dial, matching: find.text('23')),
        findsOneWidget,
      );

      // 링 맨 위(12시 방향)를 눌러 00시를 고른다.
      await tester.tapAt(center + Offset(0, -(radius - 25)));
      await tester.pumpAndSettle();

      // 이어서 분 선택으로 넘어간다.
      expect(
        find.descendant(of: dial, matching: find.text('23')),
        findsNothing,
        reason: '시를 고른 뒤 분 선택으로 넘어가야 한다',
      );
      expect(
        find.descendant(of: dial, matching: find.text('55')),
        findsOneWidget,
      );
    });

    testWidgets('$code — 고른 시각이 타일에 반영된다', (tester) async {
      await pumpAddScreen(tester, locale);
      final l10n = lookupAppLocalizations(locale);

      await tapTile(tester, l10n.routineAddStartTime);

      final dial = find.byKey(const Key('orbit-time-picker-dial'));
      final radius = tester.getSize(dial).width / 2;
      final dialCenter = tester.getCenter(dial);
      // 06시 = 3시 방향.
      await tester.tapAt(dialCenter + Offset(radius - 25, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('orbit-time-picker-confirm')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('06:00'), findsWidgets);
    });

    testWidgets('$code — 좁은 화면·큰 글꼴에서도 선택기가 넘치지 않는다', (tester) async {
      await pumpAddScreen(tester, locale,
          size: const Size(360, 640), textScale: 1.3);
      final l10n = lookupAppLocalizations(locale);

      await tapTile(tester, l10n.routineAddStartTime);

      expect(tester.takeException(), isNull);
    });

    testWidgets('$code — 반복 요일 글자가 원 안에 들어간다', (tester) async {
      await pumpAddScreen(tester, locale);

      final circles = find.byType(RoutineWeekdayCircle);
      expect(circles, findsNWidgets(7));

      for (var i = 0; i < 7; i++) {
        final text =
            find.descendant(of: circles.at(i), matching: find.byType(Text));
        final textWidth = tester.getSize(text.first).width;
        final label = (tester.widget(text.first) as Text).data;

        // 원은 39px, 테두리가 양쪽 2px. 약어('lun'·'Mon')를 쓰면 35~37px라
        // 글꼴이 조금만 넓어져도 잘린다. 한 글자 형식이어야 여유가 남는다.
        expect(textWidth, lessThan(33),
            reason: '$code 요일 "$label"이 원(39px)을 거의 채운다 '
                '— 폭 ${textWidth.toStringAsFixed(1)}');
      }
    });

    testWidgets('$code — 큰 글꼴에서도 요일 글자가 원을 넘지 않는다', (tester) async {
      await pumpAddScreen(tester, locale, textScale: 1.3);

      final circles = find.byType(RoutineWeekdayCircle);
      for (var i = 0; i < 7; i++) {
        final text =
            find.descendant(of: circles.at(i), matching: find.byType(Text));
        expect(tester.getSize(text.first).width, lessThan(39));
      }
    });

  }

  group('시간 형식은 로케일이 정한다', () {
    testWidgets('한국어·영어는 기기가 12시간제면 오전/오후가 붙는다', (tester) async {
      for (final locale in const [Locale('ko'), Locale('en')]) {
        final m = await GlobalMaterialLocalizations.delegate.load(locale);
        expect(
          m.timeOfDayFormat(alwaysUse24HourFormat: false),
          isNot(TimeOfDayFormat.HH_colon_mm),
          reason: '${locale.languageCode}는 12시간제를 쓸 수 있어야 한다',
        );
      }
    });

    testWidgets('스페인어는 기기 설정과 무관하게 24시간제다', (tester) async {
      final m = await GlobalMaterialLocalizations.delegate
          .load(const Locale('es'));
      // 이 사실 때문에 스페인어에서만 시 다이얼이 두 겹으로 그려졌다.
      // 기기를 12시간제로 두어도 마찬가지다.
      expect(m.timeOfDayFormat(alwaysUse24HourFormat: false),
          TimeOfDayFormat.H_colon_mm);
      expect(m.timeOfDayFormat(alwaysUse24HourFormat: true),
          TimeOfDayFormat.H_colon_mm);
    });
  });
}
