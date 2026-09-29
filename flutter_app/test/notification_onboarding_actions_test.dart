import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/services/notification_onboarding_actions.dart';
import 'package:routine_timer/data/local/notification_preferences_storage.dart';
import 'package:routine_timer/domain/settings/notification_permission_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('이미 켠 푸시는 나중에로 끄지 않는다', () async {
    SharedPreferences.setMockInitialValues({
      'prefs.notifications.enabled': true,
      'prefs.notifications.permission_status': 'granted',
      'prefs.notifications.sound_enabled': true,
    });

    await NotificationOnboardingActions().deferNotificationSetupLater();

    final prefs = await NotificationPreferencesStorage.load();
    expect(prefs.notificationsEnabled, isTrue);
    expect(prefs.permissionStatus, NotificationPermissionStatus.granted);
    expect(prefs.soundEnabled, isTrue);
  });

  test('첫 실행 나중에는 알림을 끈 값으로 저장한다', () async {
    SharedPreferences.setMockInitialValues({});

    await NotificationOnboardingActions().deferNotificationSetupLater();

    final prefs = await NotificationPreferencesStorage.load();
    expect(prefs.notificationsEnabled, isFalse);
    expect(prefs.permissionStatus, NotificationPermissionStatus.notRequested);
  });
}
