import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/domain/settings/app_language.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/l10n/app_localizations.dart';
import 'package:routine_timer/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_doubles.dart';

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

  /// 실제 앱과 같은 배선 — `MaterialApp.locale`이 컨트롤러를 따라간다.
  /// 로케일을 고정해 버리면 언어 전환이 화면에 반영되는지 확인할 수 없다.
  Future<RoutineAppController> pumpSettings(WidgetTester tester) async {
    final controller = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: MemoryRoutineRepository([
          dailyRoutine(id: 'wake', title: '기상', startHour: 7, endHour: 8),
        ]),
        logRepository: MemoryLogRepository(),
      ),
      notificationService: RoutineNotificationService(
        exactAlarmsAllowed: () async => false,
        gateway: NoopNotificationGateway(),
        preferencesLoader: () async =>
            NotificationPreferences.firstLaunchDefaults,
      ),
      nowProvider: () => DateTime(2026, 8, 4, 10, 0),
      clockAutoRefreshEnabled: false,
    );
    await controller.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: Consumer<RoutineAppController>(
          builder: (context, app, _) => MaterialApp(
            // 고르지 않았으면 한국어로 시작한다(기기 언어 대신 고정해야
            // 테스트가 실행 환경 언어에 흔들리지 않는다).
            locale: app.locale ?? const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  /// [ListView]는 뷰포트 밖 항목을 만들지 않는다. 개인화 섹션은 화면 아래라
  /// 언어가 길어지면 생성 범위를 벗어난다. 검증 전에 보이게 끌어온다.
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('개인화 섹션에 언어 항목이 보이고 기본값은 기기 설정 따르기다', (tester) async {
    final controller = await pumpSettings(tester);
    addTearDown(controller.dispose);

    expect(find.text('언어'), findsOneWidget);
    expect(find.text('앱에서 사용할 언어를 고르세요'), findsOneWidget);
    // 고른 적이 없으면 저장값은 비어 있어야 한다 — 기기 언어를 복사해 두면
    // 나중에 기기 언어를 바꿔도 앱이 옛 언어에 묶인다.
    expect(controller.appSettings.localeCode, isNull);
    expect(controller.language, AppLanguage.system);
    expect(find.text('기기 설정 따르기'), findsOneWidget);
  });

  testWidgets('언어 항목을 누르면 선택 시트에 네 가지가 뜬다', (tester) async {
    final controller = await pumpSettings(tester);
    addTearDown(controller.dispose);

    await tester.tap(find.text('언어'));
    await tester.pumpAndSettle();

    expect(find.text('언어 선택'), findsOneWidget);
    expect(find.text('한국어'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Español'), findsOneWidget);
    // 시트가 열리면 타일과 시트 양쪽에 같은 라벨이 있다.
    expect(find.text('기기 설정 따르기'), findsNWidgets(2));
  });

  testWidgets('스페인어를 고르면 저장되고 화면이 즉시 그 언어로 바뀐다', (tester) async {
    final controller = await pumpSettings(tester);
    addTearDown(controller.dispose);

    // 화면 제목과 하단 탭 두 곳에 나온다.
    expect(find.text('설정'), findsNWidgets(2));

    await tester.tap(find.text('언어'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();

    expect(controller.language, AppLanguage.spanish);
    expect(controller.appSettings.localeCode, 'es');

    // 재시작 없이 반영된다.
    expect(find.text('Ajustes'), findsNWidgets(2));
    await scrollTo(tester, find.text('Idioma'));
    expect(find.text('Idioma'), findsOneWidget);
    expect(find.text('설정'), findsNothing);
    expect(find.text('언어'), findsNothing);
  });

  testWidgets('기기 설정 따르기로 되돌리면 저장값이 지워진다', (tester) async {
    final controller = await pumpSettings(tester);
    addTearDown(controller.dispose);

    await controller.updateLanguage(AppLanguage.english);
    await tester.pumpAndSettle();
    expect(controller.appSettings.localeCode, 'en');

    await scrollTo(tester, find.text('Language'));
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Match device'));
    await tester.pumpAndSettle();

    // null로 지워지지 않으면 copyWith의 `??` 때문에 옛 값이 남는다.
    expect(controller.appSettings.localeCode, isNull);
    expect(controller.language, AppLanguage.system);
  });

  testWidgets('지원하지 않는 기기 언어는 한국어가 아니라 영어로 떨어진다', (tester) async {
    final controller = await pumpSettings(tester);
    addTearDown(controller.dispose);

    // 폴백을 한국어로 두면 낯선 언어권 사용자가 한글 화면을 보게 된다.
    expect(AppLanguage.fallback, AppLanguage.english);
    expect(AppLanguage.supportedLocales.first, const Locale('en'));
  });
}
