import '../../domain/settings/notification_preferences.dart';
import 'local_settings_repository.dart';

/// 이전 호출부 호환용 facade.
///
/// 실제 저장은 [LocalSettingsRepository]가 담당하므로, 새 UI 코드는
/// [SettingsRepository]를 통해 접근해야 한다.
class NotificationPreferencesStorage {
  NotificationPreferencesStorage._();

  static Future<NotificationPreferences> load() =>
      LocalSettingsRepository.instance.loadNotificationPreferences();

  static Future<void> save(NotificationPreferences prefs) =>
      LocalSettingsRepository.instance.saveNotificationPreferences(prefs);
}
