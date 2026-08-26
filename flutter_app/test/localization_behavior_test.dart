import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/settings/app_language.dart';
import 'package:routine_timer/domain/settings/notification_permission_status.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/domain/utils/app_date_formats.dart';
import 'package:routine_timer/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_doubles.dart';

/// 화면 밖에서 일어나는 다국어 동작 — 저장·복원, 알림 문구, 날짜 표기.
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

  RoutineAppController makeController({List<Routine> routines = const []}) {
    return RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: MemoryRoutineRepository(routines),
        logRepository: MemoryLogRepository(),
      ),
      notificationService: RoutineNotificationService(
        exactAlarmsAllowed: () async => false,
        gateway: NoopNotificationGateway(),
        preferencesLoader: () async =>
            NotificationPreferences.firstLaunchDefaults,
      ),
      nowProvider: () => DateTime(2026, 8, 4, 14, 30),
      clockAutoRefreshEnabled: false,
    );
  }

  group('언어 저장은 앱을 다시 켜도 남는다', () {
    test('고른 언어가 저장소에 남고 새 컨트롤러가 읽어 온다', () async {
      final first = makeController();
      await first.load();
      await first.updateLanguage(AppLanguage.spanish);
      first.dispose();

      // 앱을 다시 켠 상황.
      final second = makeController();
      await second.load();
      expect(second.language, AppLanguage.spanish);
      expect(second.resolvedLocale, const Locale('es'));
      second.dispose();
    });

    test('기기 설정 따르기로 되돌린 것도 남는다', () async {
      final first = makeController();
      await first.load();
      await first.updateLanguage(AppLanguage.english);
      await first.updateLanguage(AppLanguage.system);
      first.dispose();

      final second = makeController();
      await second.load();
      // 저장된 값이 'en'으로 남아 있으면 되돌리기가 동작하지 않은 것이다.
      expect(second.appSettings.localeCode, isNull);
      expect(second.language, AppLanguage.system);
      second.dispose();
    });

    test('저장소에 모르는 언어 코드가 있어도 기기 설정으로 떨어진다', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      // 지원 목록에서 언어를 뺀 버전으로 내려간 경우를 흉내낸다.
      // LocalSettingsRepository가 쓰는 키. 저장 형식이 바뀌면 이 테스트가
      // 먼저 알려준다.
      await prefs.setString(
        'domain.app_settings.v1',
        '{"localeCode":"pt"}',
      );

      final controller = makeController();
      await controller.load();
      expect(controller.language, AppLanguage.system);
      controller.dispose();
    });
  });

  group('언어별 문자열', () {
    test('세 언어 모두 같은 키를 채운다 — 빈 문자열이 없다', () {
      for (final locale in AppLanguage.supportedLocales) {
        final l10n = lookupAppLocalizations(locale);
        final samples = <String>[
          l10n.homeTitle,
          l10n.settingsTitle,
          l10n.settingsLanguage,
          l10n.languageSystem,
          l10n.statusCompleted,
          l10n.statusSnoozed,
          l10n.statusSkipped,
          l10n.navHome,
          l10n.navProgress,
          l10n.navRoutines,
          l10n.navSettings,
          l10n.routineAddSaveNew,
          l10n.permAllow,
          l10n.notificationChannelName,
        ];
        for (final value in samples) {
          expect(value.trim(), isNotEmpty,
              reason: '${locale.languageCode}에 비어 있는 문구가 있다');
        }
      }
    });

    test('복수형이 언어별로 맞게 나온다', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final es = lookupAppLocalizations(const Locale('es'));

      expect(en.routineCount(1), '1 routine');
      expect(en.routineCount(3), '3 routines');
      expect(es.routineCount(1), '1 rutina');
      expect(es.routineCount(3), '3 rutinas');
    });

    test('자리표시자가 실제로 채워진다', () {
      final es = lookupAppLocalizations(const Locale('es'));
      final body = es.notificationBody('Lectura');
      expect(body, contains('Lectura'));
      expect(body, isNot(contains('{')));

      final hint = es.timingUntilEnd('20 min');
      expect(hint, contains('20 min'));
      expect(hint, isNot(contains('{')));
    });
  });

  group('날짜 표기는 로케일에서 온다', () {
    test('같은 날짜가 언어마다 다르게 적힌다', () {
      final date = DateTime(2026, 8, 21);
      final ko = AppDateFormats.monthDayIn('ko', date);
      final en = AppDateFormats.monthDayIn('en', date);
      final es = AppDateFormats.monthDayIn('es', date);

      expect(ko, contains('8'));
      expect(ko, contains('21'));
      // 형식을 직접 이어붙였다면 세 언어가 같은 문자열이 된다.
      expect({ko, en, es}.length, 3, reason: '로케일별 형식이 적용되지 않았다');
    });

    test('날짜와 요일 어순을 로케일이 정한다', () {
      // 2026-08-24는 월요일.
      final date = DateTime(2026, 8, 24);
      final ko = AppDateFormats.monthDayWeekdayIn('ko', date);
      final es = AppDateFormats.monthDayWeekdayIn('es', date);

      // 직접 이어 붙이면 스페인어가 '24 ago lunes'처럼 어순이 뒤집힌다.
      expect(es.toLowerCase().indexOf('lun'), lessThan(es.indexOf('24')),
          reason: '스페인어는 요일이 먼저 온다');
      // 한국어는 '8월 24일 (월)' — 요일이 괄호로 뒤에 붙는다.
      expect(ko.indexOf('24'), lessThan(ko.indexOf('(')),
          reason: '한국어는 날짜가 먼저 온다');
    });

    test('요일 이름도 언어를 따른다', () {
      // 2024-01-01은 월요일.
      final ko = AppDateFormats.weekdayFullIn('ko', DateTime(2024, 1, 1));
      final es = AppDateFormats.weekdayFullIn('es', DateTime(2024, 1, 1));
      expect(ko, '월요일');
      expect(es.toLowerCase(), 'lunes');
    });
  });

  group('언어를 바꾸면 앱 밖으로 나간 문자열도 다시 만든다', () {
    test('예약된 알림이 새 언어로 다시 예약된다', () async {
      final gateway = RecordingNotificationGateway();
      final controller = RoutineAppController(
        dataService: RoutineDataService(
          routineRepository: MemoryRoutineRepository([
            dailyRoutine(id: 'read', title: 'Lectura', startHour: 21, endHour: 22),
          ]),
          logRepository: MemoryLogRepository(),
        ),
        notificationService: RoutineNotificationService(
          exactAlarmsAllowed: () async => false,
          gateway: gateway,
          preferencesLoader: () async => const NotificationPreferences(
            notificationsEnabled: true,
            soundEnabled: true,
            permissionStatus: NotificationPermissionStatus.granted,
          ),
        ),
        nowProvider: () => DateTime(2026, 8, 4, 14, 30),
        clockAutoRefreshEnabled: false,
      );
      await controller.load();
      await controller.updateLanguage(AppLanguage.korean);
      gateway.scheduled.clear();

      await controller.updateLanguage(AppLanguage.spanish);

      // 다시 예약하지 않으면 사용자는 몇 주 동안 옛 언어로 알림을 받는다.
      expect(gateway.scheduled, isNotEmpty,
          reason: '언어를 바꾼 뒤 알림이 다시 예약되지 않았다');
      expect(gateway.scheduled.first.body, contains('Es hora'));
      controller.dispose();
    });

    test('같은 언어를 다시 고르면 아무것도 다시 하지 않는다', () async {
      final gateway = RecordingNotificationGateway();
      final controller = RoutineAppController(
        dataService: RoutineDataService(
          routineRepository: MemoryRoutineRepository([
            dailyRoutine(id: 'read', title: 'Lectura', startHour: 21, endHour: 22),
          ]),
          logRepository: MemoryLogRepository(),
        ),
        notificationService: RoutineNotificationService(
          exactAlarmsAllowed: () async => false,
          gateway: gateway,
          preferencesLoader: () async => const NotificationPreferences(
            notificationsEnabled: true,
            soundEnabled: true,
            permissionStatus: NotificationPermissionStatus.granted,
          ),
        ),
        nowProvider: () => DateTime(2026, 8, 4, 14, 30),
        clockAutoRefreshEnabled: false,
      );
      await controller.load();
      await controller.updateLanguage(AppLanguage.spanish);
      gateway.scheduled.clear();

      await controller.updateLanguage(AppLanguage.spanish);

      expect(gateway.scheduled, isEmpty,
          reason: '바뀐 것이 없는데 알림을 다시 예약했다');
      controller.dispose();
    });
  });

  group('알림', () {
    test('예약되는 문구가 현재 언어를 따른다', () async {
      final gateway = RecordingNotificationGateway();
      final service = RoutineNotificationService(
        exactAlarmsAllowed: () async => false,
        gateway: gateway,
        preferencesLoader: () async => const NotificationPreferences(
          notificationsEnabled: true,
          soundEnabled: true,
          permissionStatus: NotificationPermissionStatus.granted,
        ),
      );
      final routine =
          dailyRoutine(id: 'read', title: 'Lectura', startHour: 21, endHour: 22);

      await service.syncAll(
        [routine],
        lookupAppLocalizations(const Locale('es')),
      );

      expect(gateway.scheduled, isNotEmpty);
      expect(gateway.scheduled.first.body, contains('Lectura'));
      expect(gateway.scheduled.first.body, contains('Es hora'));
    });
  });
}
