import 'package:flutter/foundation.dart';

import '../../data/local/local_settings_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/models/routine.dart';
import '../../domain/settings/notification_permission_status.dart';
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
  String? _errorMessage;

  NotificationPreferences get notificationPreferences =>
      _notificationPreferences;
  bool get notificationsEnabled =>
      _notificationPreferences.notificationsEnabled;
  bool get soundEnabled => _notificationPreferences.soundEnabled;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _notificationPreferences =
          await _repository.loadNotificationPreferences();
    } catch (_) {
      _errorMessage = '설정을 불러오지 못했어요. 다시 시도해 주세요.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setNotificationsEnabled(
      bool enabled, List<Routine> routines) async {
    if (_isUpdating) return;
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (!enabled) {
        await _saveAndSync(
          _notificationPreferences.copyWith(
            notificationsEnabled: false,
            soundEnabled: false,
          ),
          routines,
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
        );
      }
    } catch (_) {
      _errorMessage = '알림 설정을 저장하지 못했어요. 다시 시도해 주세요.';
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> setSoundEnabled(bool enabled, List<Routine> routines) async {
    if (_isUpdating || !notificationsEnabled) return;
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _saveAndSync(
          _notificationPreferences.copyWith(soundEnabled: enabled), routines);
    } catch (_) {
      _errorMessage = '알림 소리 설정을 저장하지 못했어요. 다시 시도해 주세요.';
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _saveAndSync(
    NotificationPreferences preferences,
    List<Routine> routines,
  ) async {
    await _repository.saveNotificationPreferences(preferences);
    _notificationPreferences = preferences;
    await _notificationService.syncAll(routines);
  }
}
