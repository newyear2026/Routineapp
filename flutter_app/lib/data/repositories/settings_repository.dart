import '../../domain/models/app_settings.dart';
import '../../domain/models/watch_state.dart';
import '../../domain/settings/notification_preferences.dart';

/// [AppSettings] + [WatchState] — 서버 연동 시 동일 인터페이스로 원격 구현체 교체
abstract class SettingsRepository {
  Future<AppSettings> loadAppSettings();

  Future<void> saveAppSettings(AppSettings settings);

  Future<WatchState> loadWatchState();

  Future<void> saveWatchState(WatchState state);

  /// 앱 전역 알림 설정. UI는 이 인터페이스를 통해서만 설정을 읽고 쓴다.
  Future<NotificationPreferences> loadNotificationPreferences();

  Future<void> saveNotificationPreferences(
    NotificationPreferences preferences,
  );
}
