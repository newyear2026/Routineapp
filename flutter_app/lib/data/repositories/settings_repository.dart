import '../../domain/models/app_settings.dart';
import '../../domain/models/watch_state.dart';

/// [AppSettings] + [WatchState] — 서버 연동 시 동일 인터페이스로 원격 구현체 교체
abstract class SettingsRepository {
  Future<AppSettings> loadAppSettings();

  Future<void> saveAppSettings(AppSettings settings);

  Future<WatchState> loadWatchState();

  Future<void> saveWatchState(WatchState state);
}
