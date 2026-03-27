import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_settings.dart';
import '../../domain/models/watch_state.dart';
import '../repositories/settings_repository.dart';

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository._();

  static final LocalSettingsRepository instance = LocalSettingsRepository._();

  static const _kSettings = 'domain.app_settings.v1';
  static const _kWatch = 'domain.watch_state.v1';

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
}
