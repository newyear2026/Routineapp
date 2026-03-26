import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_local_storage.dart';
import '../../domain/settings/notification_permission_status.dart';
import '../../domain/settings/notification_preferences.dart';

/// 알림 관련 앱 설정 — 재실행 후에도 유지.
class NotificationPreferencesStorage {
  NotificationPreferencesStorage._();

  static const _kNotificationsEnabled = 'prefs.notifications.enabled';
  static const _kPermissionStatus = 'prefs.notifications.permission_status';
  static const _kSoundEnabled = 'prefs.notifications.sound_enabled';

  static Future<NotificationPreferences> load() async {
    final p = await SharedPreferences.getInstance();
    final hasExplicit = p.containsKey(_kNotificationsEnabled);

    if (!hasExplicit) {
      final ob = await OnboardingLocalStorage.load();
      if (ob.hasHandledNotificationSetup) {
        const migrated = NotificationPreferences(
          notificationsEnabled: true,
          permissionStatus: NotificationPermissionStatus.granted,
          soundEnabled: true,
        );
        await save(migrated);
        return migrated;
      }
      return NotificationPreferences.firstLaunchDefaults;
    }

    return NotificationPreferences(
      notificationsEnabled: p.getBool(_kNotificationsEnabled) ?? false,
      permissionStatus: NotificationPermissionStatusStorage.fromRaw(
        p.getString(_kPermissionStatus),
      ),
      soundEnabled: p.getBool(_kSoundEnabled) ?? true,
    );
  }

  static Future<void> save(NotificationPreferences prefs) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNotificationsEnabled, prefs.notificationsEnabled);
    await p.setString(_kPermissionStatus, prefs.permissionStatus.toRaw);
    await p.setBool(_kSoundEnabled, prefs.soundEnabled);
  }
}
