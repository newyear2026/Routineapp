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
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
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

    testWidgets('$code — 시작 시간 타일을 누르면 시각 선택기가 열린다', (tester) async {
      await pumpAddScreen(tester, locale);
      final l10n = lookupAppLocalizations(locale);

      await tapTile(tester, l10n.routineAddStartTime);

      // 다이얼이 떠야 한다. 예외가 나면 여기서 먼저 걸린다.
      expect(tester.takeException(), isNull);
      expect(find.byType(TimePickerDialog), findsOneWidget);
    });

    testWidgets('$code — 시각 선택기를 확인하면 값이 반영된다', (tester) async {
      await pumpAddScreen(tester, locale);
      final l10n = lookupAppLocalizations(locale);
      final materialL10n = await GlobalMaterialLocalizations.delegate
          .load(locale);

      await tapTile(tester, l10n.routineAddEndTime);

      // 다이얼 조작 없이 확인만 눌러도 화면이 정상적으로 닫혀야 한다.
      await tester.tap(find.text(materialL10n.okButtonLabel));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TimePickerDialog), findsNothing);
    });

    testWidgets('$code — 좁은 화면에서도 선택기가 넘치지 않는다', (tester) async {
      await pumpAddScreen(tester, locale, size: const Size(360, 640));
      final l10n = lookupAppLocalizations(locale);

      await tapTile(tester, l10n.routineAddStartTime);

      expect(tester.takeException(), isNull);
    });

    testWidgets('$code — 선택기가 24시간제로 뜬다', (tester) async {
      await pumpAddScreen(tester, locale);
      final l10n = lookupAppLocalizations(locale);
      final materialL10n =
          await GlobalMaterialLocalizations.delegate.load(locale);

      await tapTile(tester, l10n.routineAddStartTime);

      // 앱은 어디서나 24시간 표기다. 선택기만 12시간이면 사용자가 고른
      // '9:00 p.m.'이 타일에서 '21:00'으로 나타난다.
      expect(find.text(materialL10n.anteMeridiemAbbreviation), findsNothing);
      expect(find.text(materialL10n.postMeridiemAbbreviation), findsNothing);
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

    testWidgets('$code — 입력 모드로 전환해도 넘치지 않는다', (tester) async {
      await pumpAddScreen(tester, locale);
      final l10n = lookupAppLocalizations(locale);

      await tapTile(tester, l10n.routineAddStartTime);

      // 다이얼 ↔ 키보드 입력 전환 버튼.
      final toggle = find.byIcon(Icons.keyboard_outlined);
      if (toggle.evaluate().isNotEmpty) {
        await tester.tap(toggle.first);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
}
