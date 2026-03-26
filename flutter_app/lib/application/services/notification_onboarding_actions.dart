import '../../data/local/notification_preferences_storage.dart';
import '../../data/local/onboarding_local_storage.dart';
import '../../domain/settings/notification_permission_status.dart';
import '../../domain/settings/notification_preferences.dart';
import 'notification_permission_service.dart';

/// 온보딩 알림 단계 — «허용» / «나중에» 처리.
///
/// - [deferNotificationSetupLater]: 앱 알림 OFF, 권한 미요청, 온보딩 단계 완료.
/// - [completeWithSystemPermissionRequest]: 시스템 권한 요청 후 결과에 따라 저장·온보딩 완료.
class NotificationOnboardingActions {
  NotificationOnboardingActions({
    NotificationPermissionService? permissionService,
  }) : _permission = permissionService ?? NotificationPermissionService.instance;

  final NotificationPermissionService _permission;

  /// «나중에 설정할게요» — 알림을 켜지 않고, 온보딩만 끝낸다.
  Future<void> deferNotificationSetupLater() async {
    await NotificationPreferencesStorage.save(
      const NotificationPreferences(
        notificationsEnabled: false,
        permissionStatus: NotificationPermissionStatus.notRequested,
        soundEnabled: false,
      ),
    );
    await OnboardingLocalStorage.markNotificationSetupHandled();
  }

  /// «알림 허용하기» — 시스템 권한 요청 후 상태 반영.
  Future<void> completeWithSystemPermissionRequest() async {
    final granted = await _permission.requestPostNotificationsPermission();
    if (granted) {
      await NotificationPreferencesStorage.save(
        const NotificationPreferences(
          notificationsEnabled: true,
          permissionStatus: NotificationPermissionStatus.granted,
          soundEnabled: true,
        ),
      );
    } else {
      await NotificationPreferencesStorage.save(
        const NotificationPreferences(
          notificationsEnabled: false,
          permissionStatus: NotificationPermissionStatus.denied,
          soundEnabled: false,
        ),
      );
    }
    await OnboardingLocalStorage.markNotificationSetupHandled();
  }
}
