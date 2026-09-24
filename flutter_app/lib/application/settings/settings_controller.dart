import 'package:flutter/foundation.dart';

import '../../data/local/local_settings_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/models/routine.dart';
import '../../domain/settings/notification_permission_status.dart';
import '../../domain/settings/settings_error.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/settings/notification_preferences.dart';
import '../services/notification_permission_service.dart';
import '../services/routine_notification_service.dart';

/// 설정 화면의 상태 전환과 저장을 담당한다.
///
/// 화면은 이 컨트롤러의 상태만 관찰하고, SharedPreferences나 권한 API를 직접
/// 호출하지 않는다.
class SettingsController extends ChangeNotifier {
  SettingsController({
    SettingsRepository? repository,
    NotificationPermissionService? permissionService,
    RoutineNotificationService? notificationService,
  })  : _repository = repository ?? LocalSettingsRepository.instance,
        _permissionService =
            permissionService ?? NotificationPermissionService.instance,
        _notificationService =
            notificationService ?? RoutineNotificationService();

  final SettingsRepository _repository;
  final NotificationPermissionService _permissionService;
  final RoutineNotificationService _notificationService;

  NotificationPreferences _notificationPreferences =
      NotificationPreferences.firstLaunchDefaults;
  bool _isLoading = true;
  bool _isUpdating = false;
  SettingsError? _error;

  NotificationPreferences get notificationPreferences =>
      _notificationPreferences;
  bool get notificationsEnabled =>
      _notificationPreferences.notificationsEnabled;
  bool get soundEnabled => _notificationPreferences.soundEnabled;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  SettingsError? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _notificationPreferences =
          await _repository.loadNotificationPreferences();
    } catch (_) {
      _error = SettingsError.load;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// [l10n]은 알림 문구를 만드는 데 쓴다 — 알림은 위젯 트리 밖에서 예약된다.
  Future<void> setNotificationsEnabled(
      bool enabled, List<Routine> routines, AppLocalizations l10n) async {
    if (_isUpdating) return;
    _isUpdating = true;
    _error = null;
    notifyListeners();
    try {
      if (!enabled) {
        await _saveAndSync(
          _notificationPreferences.copyWith(
            notificationsEnabled: false,
            soundEnabled: false,
          ),
          routines,
          l10n,
        );
      } else {
        final granted =
            await _permissionService.requestPostNotificationsPermission();
        await _saveAndSync(
          NotificationPreferences(
            notificationsEnabled: granted,
            permissionStatus: granted
                ? NotificationPermissionStatus.granted
                : NotificationPermissionStatus.denied,
            soundEnabled: granted,
          ),
          routines,
          l10n,
        );
      }
    } catch (_) {
      _error = SettingsError.saveNotifications;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> setSoundEnabled(
      bool enabled, List<Routine> routines, AppLocalizations l10n) async {
    if (_isUpdating || !notificationsEnabled) return;
    _isUpdating = true;
    _error = null;
    notifyListeners();
    try {
      await _saveAndSync(
        _notificationPreferences.copyWith(soundEnabled: enabled),
        routines,
        l10n,
      );
    } catch (_) {
      _error = SettingsError.saveSound;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> _saveAndSync(
    NotificationPreferences preferences,
    List<Routine> routines,
    AppLocalizations l10n,
  ) async {
    await _repository.saveNotificationPreferences(preferences);
    _notificationPreferences = preferences;
    await _notificationService.syncAll(routines, l10n);
  }
}
