import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/models/routine_icon_id.dart';
import 'package:routine_timer/l10n/app_localizations.dart';
import 'package:routine_timer/screens/routine_add_screen.dart';
import 'package:routine_timer/screens/routine_add/sleep_routine_fields.dart';
import 'package:routine_timer/screens/routine_add/sleep_routine_entry_card.dart';
import 'package:routine_timer/screens/routine_add/routine_form_controls.dart';
import 'package:routine_timer/screens/routine_add/routine_form_preview.dart';
import 'package:routine_timer/theme/app_theme.dart';
import 'package:routine_timer/theme/app_theme_preset.dart';
import 'package:routine_timer/widgets/ds/app_pixel_switch.dart';
import 'package:routine_timer/widgets/ds/pixel_icon.dart';
import 'package:routine_timer/widgets/ds/routine_mark.dart';
import 'package:routine_timer/widgets/form/pastel_color_palette.dart';
import 'support/localization.dart';
import 'support/routine_test_harness.dart';
import 'sleep_routine_test.dart' show sleep;

void main() {
  setUpRoutineTestEnvironment();
  final boundary = GlobalKey();
  const output = String.fromEnvironment('SLEEP_SCREENSHOT_OUTPUT');

  Future<RoutineAppController> pump(
    WidgetTester tester, {
    Locale locale = testLocale,
    List<Routine> routines = const [],
    String? editId,
    bool startSleep = true,
    int? initialWeekday,
    bool returnToRoutines = false,
    AppThemePreset preset = AppThemePreset.softDay,
    double width = 390,
    double scale = 1,
  }) async {
    tester.view
      ..physicalSize = Size(width, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = createTestRoutineController(
      now: DateTime(2026, 10, 5, 10),
      routines: routines,
    );
    await app.load();
    addTearDown(app.dispose);
    final router = GoRouter(
      initialLocation: editId != null
          ? '/routine-add?id=$editId'
          : startSleep
              ? '/routine-add?type=sleep'
              : Uri(
                  path: '/routine-add',
                  queryParameters: {
                    if (initialWeekday != null) 'weekday': '$initialWeekday',
                    if (returnToRoutines) 'returnTo': 'routines',
                  },
                ).toString(),
      routes: [
        GoRoute(
          path: '/routine-add',
          builder: (context, state) => RoutineAddScreen(
            key: ValueKey(state.uri.toString()),
            editRoutineId: state.uri.queryParameters['id'],
            initialWeekday: int.tryParse(
              state.uri.queryParameters['weekday'] ?? '',
            ),
            returnToRoutines:
                state.uri.queryParameters['returnTo'] == 'routines',
            initialType: state.uri.queryParameters['type'] == 'sleep'
                ? RoutineType.sleep
                : RoutineType.activity,
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('saved-home')),
        ),
        GoRoute(
          path: '/routines',
          builder: (_, __) => const Scaffold(body: Text('saved-routines')),
        ),
      ],
    );
    addTearDown(router.dispose);
    if (output.isNotEmpty) {
      final font = FontLoader('SleepPreview')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File(
                const String.fromEnvironment('SLEEP_PREVIEW_FONT'),
              ).readAsBytesSync(),
            ),
          ),
        );
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File(
                const String.fromEnvironment('SLEEP_ICON_FONT'),
              ).readAsBytesSync(),
            ),
          ),
        );
      await icons.load();
    }
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp.router(
          routerConfig: router,
          locale: locale,
          theme: buildRoutineTheme(
            preset: preset,
            fontFamily: output.isEmpty ? null : 'SleepPreview',
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: RepaintBoundary(key: boundary, child: child),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return app;
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (output.isEmpty) return;
    await tester.runAsync(() async {
      for (final path in [
        'assets/routine_icons/moon.png',
        'assets/routine_icons/coffee.png',
        'assets/decorations/settings-card-cloud.png',
      ]) {
        await precacheImage(AssetImage(path), boundary.currentContext!);
      }
    });
    await tester.pumpAndSettle();
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await render.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$output/$name.png');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('sleep entry is above preview with original eight themed tags', (
    tester,
  ) async {
    await pump(tester, startSleep: false, preset: AppThemePreset.stargazer);
    final card = find.byType(SleepRoutineEntryCard);
    final preview = find.byType(RoutineFormPreview);
    expect(
      tester.getTopLeft(card).dy,
      greaterThanOrEqualTo(
        tester.getBottomLeft(find.byType(RoutineFormHeader)).dy,
      ),
    );
    expect(
      tester.getBottomLeft(card).dy,
      lessThan(tester.getTopLeft(preview).dy),
    );
    expect(find.text('수면 루틴 만들기'), findsOneWidget);
    expect(find.text('취침 시간과 기상 알림을 설정해요'), findsOneWidget);
    expect(
      tester
          .widget<RoutineMark>(
            find.descendant(of: card, matching: find.byType(RoutineMark)),
          )
          .icon,
      RoutineIconId.moon,
    );
    expect(
      tester
          .widget<PixelIcon>(
            find.descendant(of: card, matching: find.byType(PixelIcon)),
          )
          .glyph,
      PixelGlyph.chevronRight,
    );
    expect(find.byType(RoutineSuggestionChip), findsNWidgets(8));
    expect(find.widgetWithText(RoutineSuggestionChip, '취침 준비'), findsOneWidget);
    expect(find.ancestor(of: card, matching: find.byType(Wrap)), findsNothing);
    expect(
      tester
          .widget<ActionChip>(find.byType(ActionChip).first)
          .labelStyle
          ?.color,
      AppThemePreset.stargazer.primaryColor,
    );
    expect(
      Theme.of(tester.element(card)).colorScheme.primary,
      AppThemePreset.stargazer.primaryColor,
    );
    await capture(tester, 'routine-add-top-sleep-card');
  });

  testWidgets('back cancels sleep draft and keeps every ordinary form field', (
    tester,
  ) async {
    final app = await pump(tester, startSleep: false);
    await tester.enterText(find.byType(TextField), '내 저녁 루틴');
    FocusManager.instance.primaryFocus?.unfocus();
    final times = [
      const TimeOfDay(hour: 21, minute: 10),
      const TimeOfDay(hour: 22, minute: 20),
    ];
    for (var i = 0; i < times.length; i++) {
      final tile = find.byType(RoutineTimeTile).at(i);
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();
      // Exercise the real picker route and supply its selected result.
      Navigator.of(tester.element(find.byType(Dialog))).pop(times[i]);
      await tester.pumpAndSettle();
    }
    for (final day in [1, 7]) {
      final chip = find.byKey(Key('routine-weekday-$day'));
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
    }
    final palette = tester.widget<PastelColorPalette>(
      find.byType(PastelColorPalette),
    );
    palette.onSelected(0);
    await tester.pump();
    final icon = find.byKey(const Key('routine-icon-dumbbell'));
    await tester.ensureVisible(icon);
    await tester.pumpAndSettle();
    await tester.tap(icon);
    final alarm = find.byType(AppPixelSwitch);
    await tester.ensureVisible(alarm);
    await tester.pumpAndSettle();
    await tester.tap(alarm);
    await tester.pumpAndSettle();
    final card = find.byKey(const Key('choose-sleep'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
    final wakeAlarm = find.byKey(const Key('sleep-wake-alarm'));
    await tester.ensureVisible(wakeAlarm);
    await tester.pumpAndSettle();
    await tester.tap(wakeAlarm);
    tester.widget<RoutineFormHeader>(find.byType(RoutineFormHeader)).onBack();
    await tester.pumpAndSettle();
    expect(find.byType(SleepRoutineFields), findsNothing);
    expect(app.routines, isEmpty);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '내 저녁 루틴',
    );
    await tester.tap(find.text('루틴 저장'));
    await tester.pumpAndSettle();
    final saved = app.routines.single;
    expect(saved.type, RoutineType.activity);
    expect(saved.title, '내 저녁 루틴');
    expect(saved.startMinutesFromMidnight, 1270);
    expect(saved.endMinutesFromMidnight, 1340);
    expect(saved.repeatWeekdays, {2, 3, 4, 5, 7});
    expect(saved.iconId, RoutineIconId.dumbbell);
    expect(saved.colorValue, palette.colors[0].toARGB32());
    expect(saved.notificationEnabled, false);
    expect(saved.wakeNotificationEnabled, false);
  });

  testWidgets('rapid entry taps push once and back allows another entry', (
    tester,
  ) async {
    await pump(tester, startSleep: false);
    final card = find.byType(SleepRoutineEntryCard);
    final open = tester.widget<SleepRoutineEntryCard>(card).onTap!;
    // Both callbacks run before a frame can disable the card.
    open();
    open();
    await tester.pumpAndSettle();
    expect(
      find.byType(SleepRoutineFields, skipOffstage: false),
      findsOneWidget,
    );
    final router = GoRouter.of(tester.element(find.byType(SleepRoutineFields)));
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(SleepRoutineFields, skipOffstage: false), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(SleepRoutineFields), findsOneWidget);
    expect(find.byType(SleepRoutineEntryCard), findsNothing);
  });

  testWidgets(
    'calendar weekday and routines return destination survive entry',
    (tester) async {
      final app = await pump(
        tester,
        startSleep: false,
        initialWeekday: DateTime.sunday,
        returnToRoutines: true,
      );
      await tester.tap(find.byType(SleepRoutineEntryCard));
      await tester.pumpAndSettle();
      await tester.tap(find.text('루틴 저장'));
      await tester.pumpAndSettle();
      expect(app.routines.single.repeatWeekdays, {DateTime.sunday});
      expect(find.text('saved-routines'), findsOneWidget);
    },
  );

  testWidgets(
    'explicit sleep choice opens dedicated form and saves typed weekday sleep',
    (tester) async {
      final app = await pump(tester, startSleep: false);
      await tester.ensureVisible(find.byKey(const Key('choose-sleep')));
      await tester.pumpAndSettle();
      await capture(tester, 'routine-add-sleep-entry');
      await tester.tap(find.byKey(const Key('choose-sleep')));
      await tester.pumpAndSettle();
      expect(find.byType(SleepRoutineFields), findsOneWidget);
      expect(find.text('어느 요일에 일어날까요?'), findsOneWidget);
      expect(find.text('월~금 오전 7시에 알려드려요'), findsOneWidget);
      expect(find.text('총 8시간'), findsOneWidget);
      expect(find.text('일어날 시간에 알려드려요.'), findsOneWidget);
      expect(find.text('알림 설정에 따라 소리가 안 날 수 있어요.'), findsOneWidget);
      // 새 수면 루틴은 취침 30분 전 알림을 켠 채로, 알람 울리기는 끈 채로 시작한다.
      expect(
        tester
            .widget<AppPixelSwitch>(
                find.byKey(const Key('sleep-bedtime-reminder')))
            .value,
        true,
      );
      expect(
        tester
            .widget<AppPixelSwitch>(
                find.byKey(const Key('sleep-wake-alarm-loud')))
            .value,
        false,
      );
      await capture(tester, 'sleep-default-on');
      await tester.tap(find.text('루틴 저장'));
      await tester.pumpAndSettle();
      expect(app.routines, hasLength(1));
      final saved = app.routines.single;
      expect(saved.type, RoutineType.sleep);
      expect(saved.repeatWeekdays, {1, 2, 3, 4, 5});
      expect(saved.startMinutesFromMidnight, 1380);
      expect(saved.endMinutesFromMidnight, 420);
      expect(saved.notificationEnabled, false);
      expect(saved.wakeNotificationEnabled, true);
      expect(saved.bedtimeReminderEnabled, true);
      expect(saved.bedtimeReminderLeadMinutes, 30);
      expect(saved.wakeAlarmEnabled, false);
    },
  );

  testWidgets('취침 알림 시점과 알람 울리기를 골라 저장한다', (tester) async {
    final app = await pump(tester);
    final lead = find.byKey(const Key('sleep-bedtime-lead-60'));
    await tester.ensureVisible(lead);
    await tester.pumpAndSettle();
    expect(find.text('정각'), findsOneWidget);
    expect(find.text('15분 전'), findsOneWidget);
    expect(find.text('30분 전'), findsOneWidget);
    expect(find.text('1시간 전'), findsOneWidget);
    await tester.tap(lead);
    await tester.pumpAndSettle();

    final loud = find.byKey(const Key('sleep-wake-alarm-loud'));
    await tester.ensureVisible(loud);
    await tester.pumpAndSettle();
    await tester.tap(loud);
    await tester.pumpAndSettle();
    expect(find.text('확인할 때까지 알람 소리로 반복해요.'), findsOneWidget);
    expect(find.text('진동 모드에서도 울려요.'), findsOneWidget);
    // 알람으로 울리면 «소리가 안 날 수 있어요»는 틀린 말이 된다.
    expect(find.text('알림 설정에 따라 소리가 안 날 수 있어요.'), findsNothing);
    await capture(tester, 'sleep-bedtime-and-loud-alarm');

    await tester.tap(find.text('루틴 저장'));
    await tester.pumpAndSettle();
    final saved = app.routines.single;
    expect(saved.bedtimeReminderLeadMinutes, 60);
    expect(saved.wakeAlarmEnabled, true);
  });

  testWidgets('취침 알림을 끄면 시점 선택을 숨기고 꺼진 채 저장한다', (tester) async {
    final app = await pump(tester);
    final toggle = find.byKey(const Key('sleep-bedtime-reminder'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sleep-bedtime-lead-30')), findsNothing);

    // 기상 알림을 끄면 알람 울리기도 고를 수 없다.
    final wake = find.byKey(const Key('sleep-wake-alarm'));
    await tester.ensureVisible(wake);
    await tester.pumpAndSettle();
    await tester.tap(wake);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sleep-wake-alarm-loud')), findsNothing);

    await tester.tap(find.text('루틴 저장'));
    await tester.pumpAndSettle();
    expect(app.routines.single.bedtimeReminderEnabled, false);
    expect(app.routines.single.wakeNotificationEnabled, false);
  });

  testWidgets('another alert at wake time is flagged and can be turned off', (
    tester,
  ) async {
    // 첫 실행 기본 «기상 07:00» 루틴과 수면 기상 알림이 같은 시각에 온다.
    const wake = Routine(
      id: 'wake',
      title: '기상',
      startMinutesFromMidnight: 420,
      endMinutesFromMidnight: 450,
      repeatWeekdays: {1, 2, 3, 4, 5, 6, 7},
      colorValue: 0xFFFF746C,
      iconEmoji: '',
    );
    final app = await pump(tester, routines: [wake]);
    final notice = find.byKey(const Key('sleep-wake-same-time'));
    await tester.ensureVisible(notice);
    await tester.pumpAndSettle();
    expect(
      find.text("오전 7:00 '기상' 루틴도 알림을 보내요.\n같은 시각에 알림이 두 번 와요."),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('sleep-wake-alarm-off')));
    await tester.pumpAndSettle();
    expect(notice, findsNothing);
    expect(
      tester
          .widget<AppPixelSwitch>(find.byKey(const Key('sleep-wake-alarm')))
          .value,
      false,
    );
    await tester.tap(find.text('루틴 저장'));
    await tester.pumpAndSettle();
    expect(
      app.routines.singleWhere((r) => r.isSleep).wakeNotificationEnabled,
      false,
    );
  });

  testWidgets('no flag when the other routine is silent or on other days', (
    tester,
  ) async {
    const base = Routine(
      id: 'wake',
      title: '기상',
      startMinutesFromMidnight: 420,
      endMinutesFromMidnight: 450,
      repeatWeekdays: {6, 7},
      colorValue: 0xFFFF746C,
      iconEmoji: '',
    );
    await pump(tester, routines: [
      base,
      base.copyWith(
          id: 'quiet', repeatWeekdays: {1}, notificationEnabled: false),
    ]);
    expect(find.byKey(const Key('sleep-wake-same-time')), findsNothing);
  });

  testWidgets('wake alarm off changes summary and persists without promise', (
    tester,
  ) async {
    final app = await pump(tester);
    final toggle = find.byKey(const Key('sleep-wake-alarm'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text('월~금 오전 7시에 일어나는 일정이에요'), findsOneWidget);
    expect(find.text('월~금 오전 7시에 알려드려요'), findsNothing);
    await capture(tester, 'sleep-alarm-off');
    await tester.tap(find.text('루틴 저장'));
    await tester.pumpAndSettle();
    expect(app.routines.single.wakeNotificationEnabled, false);
  });

  testWidgets(
    'typed sleep edit reuses form; activity named sleep stays ordinary',
    (tester) async {
      await pump(tester, routines: [sleep], editId: 'sleep');
      expect(find.byType(SleepRoutineFields), findsOneWidget);
      expect(find.byType(SleepRoutineEntryCard), findsNothing);
      expect(
        tester
            .widget<AppPixelSwitch>(find.byKey(const Key('sleep-wake-alarm')))
            .value,
        true,
      );
      await tester.pumpWidget(const SizedBox());
      await pump(
        tester,
        routines: [
          sleep.copyWith(
            type: RoutineType.activity,
            title: '수면',
            endMinutesFromMidnight: 1440,
          ),
        ],
        editId: 'sleep',
      );
      expect(find.byType(SleepRoutineFields), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(SleepRoutineEntryCard), findsNothing);
    },
  );

  testWidgets('equal sleep times show inline error; no days cannot save', (
    tester,
  ) async {
    final app = await pump(
      tester,
      routines: [sleep.copyWith(endMinutesFromMidnight: 1380)],
      editId: 'sleep',
    );
    await tester.tap(find.text('변경사항 저장'));
    await tester.pumpAndSettle();
    expect(find.textContaining('취침·기상 시각을 다르게'), findsOneWidget);
    expect(app.routines.single.updatedAtMs, 123);
    for (var day = 1; day <= 5; day++) {
      final chip = find.byKey(Key('routine-weekday-$day'));
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pump();
    }
    await tester.tap(find.text('변경사항 저장'));
    await tester.pumpAndSettle();
    expect(find.text('반복 요일을 하루 이상 선택해 주세요.'), findsOneWidget);
    expect(app.routines.single.repeatWeekdays, {1, 2, 3, 4, 5});
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      '${locale.languageCode}: sleep entry wraps on small screen with large text',
      (tester) async {
        await pump(
          tester,
          startSleep: false,
          locale: locale,
          width: 320,
          scale: 1.4,
        );
        expect(tester.takeException(), isNull);
        final card = find.byType(SleepRoutineEntryCard);
        final l10n = AppLocalizations.of(tester.element(card));
        expect(find.text(l10n.sleepCreateTitle), findsOneWidget);
        expect(find.text(l10n.sleepCreateDescription), findsOneWidget);
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(find.byType(SleepRoutineFields), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      '${locale.languageCode}: sleep layout supports small screen and large text',
      (tester) async {
        await pump(tester, locale: locale, width: 320, scale: 1.4);
        expect(tester.takeException(), isNull);
        final toggle = find.byKey(const Key('sleep-wake-alarm'));
        await tester.ensureVisible(toggle);
        await tester.pumpAndSettle();
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
