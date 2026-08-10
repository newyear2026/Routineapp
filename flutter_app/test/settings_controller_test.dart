import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/settings/settings_controller.dart';
import 'package:routine_timer/data/repositories/settings_repository.dart';
import 'package:routine_timer/domain/models/app_settings.dart';
import 'package:routine_timer/domain/models/watch_state.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';

void main() {
  test('settings controller recovers when saving notification settings fails',
      () async {
    final controller =
        SettingsController(repository: _FailingSettingsRepository());

    await controller.load();
    await controller.setNotificationsEnabled(false, const []);

    expect(controller.isUpdating, isFalse);
    expect(controller.errorMessage, isNotNull);
  });
}

class _FailingSettingsRepository implements SettingsRepository {
  @override
  Future<NotificationPreferences> loadNotificationPreferences() async =>
      NotificationPreferences.firstLaunchDefaults;

  @override
  Future<void> saveNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    throw StateError('storage unavailable');
  }

  @override
  Future<AppSettings> loadAppSettings() async => const AppSettings();

  @override
  Future<void> saveAppSettings(AppSettings settings) async {}

  @override
  Future<WatchState> loadWatchState() async => const WatchState();

  @override
  Future<void> saveWatchState(WatchState state) async {}
}
