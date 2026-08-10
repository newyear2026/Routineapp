import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_settings.dart';
import '../../domain/models/watch_state.dart';
import '../../domain/settings/notification_permission_status.dart';
import '../../domain/settings/notification_preferences.dart';
import '../repositories/settings_repository.dart';
import 'onboarding_local_storage.dart';

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository._();

  static final LocalSettingsRepository instance = LocalSettingsRepository._();

  static const _kSettings = 'domain.app_settings.v1';
  static const _kWatch = 'domain.watch_state.v1';
  static const _kNotificationsEnabled = 'prefs.notifications.enabled';
  static const _kPermissionStatus = 'prefs.notifications.permission_status';
  static const _kSoundEnabled = 'prefs.notifications.sound_enabled';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<AppSettings> loadAppSettings() async {
    final raw = (await _prefs).getString(_kSettings);
    if (raw == null || raw.isEmpty) return const AppSettings();
    return AppSettings.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  @override
  Future<void> saveAppSettings(AppSettings settings) async {
    await (await _prefs).setString(_kSettings, jsonEncode(settings.toJson()));
  }

  @override
  Future<WatchState> loadWatchState() async {
    final raw = (await _prefs).getString(_kWatch);
    if (raw == null || raw.isEmpty) return const WatchState();
    return WatchState.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  @override
  Future<void> saveWatchState(WatchState state) async {
    await (await _prefs).setString(_kWatch, jsonEncode(state.toJson()));
  }

  @override
  Future<NotificationPreferences> loadNotificationPreferences() async {
    final prefs = await _prefs;
    final hasExplicitPreference = prefs.containsKey(_kNotificationsEnabled);
    if (!hasExplicitPreference) {
      final onboarding = await OnboardingLocalStorage.load();
      if (onboarding.hasHandledNotificationSetup) {
        const migrated = NotificationPreferences(
          notificationsEnabled: true,
          permissionStatus: NotificationPermissionStatus.granted,
          soundEnabled: true,
        );
        await saveNotificationPreferences(migrated);
        return migrated;
      }
      return NotificationPreferences.firstLaunchDefaults;
    }

    return NotificationPreferences(
      notificationsEnabled: prefs.getBool(_kNotificationsEnabled) ?? false,
      permissionStatus: NotificationPermissionStatusStorage.fromRaw(
        prefs.getString(_kPermissionStatus),
      ),
      soundEnabled: prefs.getBool(_kSoundEnabled) ?? true,
    );
  }

  @override
  Future<void> saveNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    final prefs = await _prefs;
    await prefs.setBool(
        _kNotificationsEnabled, preferences.notificationsEnabled);
    await prefs.setString(
        _kPermissionStatus, preferences.permissionStatus.toRaw);
    await prefs.setBool(_kSoundEnabled, preferences.soundEnabled);
  }
}
