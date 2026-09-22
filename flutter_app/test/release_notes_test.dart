import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/release/release_announcements.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/app_version_service.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/application/update/app_updates_controller.dart';
import 'package:routine_timer/data/local/release_notes_storage.dart';
import 'package:routine_timer/data/seed/release_notes.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/domain/update/app_update_port.dart';
import 'package:routine_timer/l10n/app_localizations.dart';
import 'package:routine_timer/screens/release_notes_screen.dart';
import 'package:routine_timer/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/localization.dart';
import 'support/test_doubles.dart';

AppVersionLoader _running(String? version) => () async =>
    version == null ? null : AppVersion(version: version, buildNumber: '2');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const homeWidgetChannel = MethodChannel('home_widget');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, (call) async => true);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, null);
  });

  group('릴리스 노트 데이터', () {
    test('보관 규칙이 허락한 개수를 넘지 않는다', () {
      expect(
        releaseNotes.length,
        lessThanOrEqualTo(releaseNoteRetention),
        reason: '버전을 추가했다면 가장 오래된 항목과 그 ARB 키를 함께 지워야 한다',
      );
    });

    test('최신이 먼저다', () {
      final dates = releaseNotes.map((note) => note.releasedOn).toList();
      final sorted = [...dates]..sort((a, b) => b.compareTo(a));
      expect(dates, sorted);
    });

    test('한 버전을 한 번만 적는다', () {
      final versions = releaseNotes.map((note) => note.version).toList();
      expect(versions.toSet().length, versions.length);
    });

    test('버전마다 적어도 한 줄을 들고 있다', () {
      for (final note in releaseNotes) {
        expect(note.lines, isNotEmpty, reason: '${note.version}에 줄이 없다');
      }
    });

    test('앱이 내보내는 모든 언어에서 줄이 읽힌다', () {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = lookupAppLocalizations(locale);
        for (final note in releaseNotes) {
          for (final line in note.lines) {
            expect(
              line(l10n).trim(),
              isNotEmpty,
              reason: '${note.version} · ${locale.languageCode}',
            );
          }
        }
      }
    });
  });

  group('릴리스 노트 화면', () {
    Future<ReleaseAnnouncements> pumpNotes(
      WidgetTester tester, {
      String? version = '1.0.1',
    }) async {
      final announcements = ReleaseAnnouncements(
        versionLoader: _running(version),
      );
      await announcements.start();

      await tester.pumpWidget(
        ChangeNotifierProvider<ReleaseAnnouncements>.value(
          value: announcements,
          child: localizedApp(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const ReleaseNotesScreen(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return announcements;
    }

    testWidgets('버전마다 카드를 그리고 돌고 있는 빌드를 표시한다', (tester) async {
      await pumpNotes(tester);

      for (final note in releaseNotes) {
        expect(find.text('v${note.version}'), findsOneWidget);
      }
      expect(find.text(testL10n.releaseNotesCurrentBadge), findsOneWidget);
    });

    testWidgets('플랫폼이 빌드를 말하지 않으면 아무 카드도 표시하지 않는다', (tester) async {
      await pumpNotes(tester, version: null);

      expect(find.text(testL10n.releaseNotesCurrentBadge), findsNothing);
      // 카드 자체는 그대로 있다 — 읽을 것이 없어지는 것은 아니다.
      expect(find.text('v${releaseNotes.first.version}'), findsOneWidget);
    });

    testWidgets('여는 것만으로 읽은 것이 된다', (tester) async {
      SharedPreferences.setMockInitialValues({
        'device.notes.announced_version': '1.0.0',
        'device.notes.read_version': '1.0.0',
      });
      final announcements = await pumpNotes(tester);

      expect(announcements.hasUnreadNotes, isFalse);
      final record = await ReleaseNotesStorage.load();
      expect(record.readVersion, '1.0.1');
    });

    testWidgets('보관 개수를 사용자에게 알린다', (tester) async {
      await pumpNotes(tester);

      expect(
        find.text(testL10n.releaseNotesRetentionHint(releaseNoteRetention)),
        findsOneWidget,
      );
    });
  });

  group('설정의 지원 및 정보', () {
    Future<void> pumpSettings(
      WidgetTester tester, {
      String? version = '1.0.1',
      AppUpdatePort port = const UnavailableUpdatePort(),
    }) async {
      final app = RoutineAppController(
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
        nowProvider: () => DateTime(2026, 9, 22, 10),
        // 켜 두면 분이 바뀔 때를 노리는 타이머가 남아, 위젯 트리를 버린 뒤에도
        // 테스트가 «타이머가 아직 있다»로 실패한다.
        clockAutoRefreshEnabled: false,
      );
      await app.load();
      addTearDown(app.dispose);

      final announcements = ReleaseAnnouncements(
        versionLoader: _running(version),
      );
      await announcements.start();

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<RoutineAppController>.value(value: app),
          ChangeNotifierProvider<ReleaseAnnouncements>.value(
            value: announcements,
          ),
          ChangeNotifierProvider<AppUpdates>(
            create: (_) => AppUpdates(port: port),
          ),
        ],
        child: localizedApp(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const SettingsScreen(),
              ),
              GoRoute(
                path: '/release-notes',
                builder: (context, state) => const ReleaseNotesScreen(),
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    /// 지원 및 정보 섹션은 목록 맨 아래에 있어 기본 뷰포트에서는 접혀 있다.
    Future<void> scrollTo(WidgetTester tester, Finder target) async {
      await tester.scrollUntilVisible(
        target,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('플랫폼이 답하면 돌고 있는 버전을 보여 준다', (tester) async {
      await pumpSettings(tester);

      await scrollTo(tester, find.text(testL10n.settingsVersion));
      expect(find.text('1.0.1 (2)'), findsOneWidget);
    });

    testWidgets('답하지 않으면 추측 대신 줄표를 보여 준다', (tester) async {
      await pumpSettings(tester, version: null);

      await scrollTo(tester, find.text(testL10n.settingsVersion));
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('물어볼 스토어가 없으면 «업데이트 확인» 행이 아예 없다', (tester) async {
      await pumpSettings(tester);

      await scrollTo(tester, find.text(testL10n.settingsVersion));
      expect(find.text(testL10n.settingsCheckUpdate), findsNothing);
    });

    testWidgets('물어볼 스토어가 있으면 «업데이트 확인» 행이 있다', (tester) async {
      await pumpSettings(tester, port: _QuietPort());

      await scrollTo(tester, find.text(testL10n.settingsCheckUpdate));
      expect(find.text(testL10n.settingsCheckUpdate), findsOneWidget);
    });

    testWidgets('«새로운 소식» 행에서 노트를 연다', (tester) async {
      await pumpSettings(tester);

      await scrollTo(tester, find.text(testL10n.settingsReleaseNotes));
      await tester.tap(find.text(testL10n.settingsReleaseNotes));
      await tester.pumpAndSettle();

      expect(find.text(testL10n.releaseNotesTitle), findsOneWidget);
      expect(
        find.text(testL10n.releaseNotesRetentionHint(releaseNoteRetention)),
        findsOneWidget,
      );
    });
  });
}

/// 물어볼 수는 있으나 기다리는 것이 없는 스토어.
class _QuietPort implements AppUpdatePort {
  @override
  bool get canCheck => true;

  @override
  Future<PendingUpdate?> check() async => null;

  @override
  Future<bool> openStore() async => false;
}
