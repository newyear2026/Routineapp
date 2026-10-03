import '../../data/local/notification_preferences_storage.dart';
import '../../data/local/onboarding_local_storage.dart';
import '../../domain/settings/notification_permission_status.dart';
import 'notification_permission_service.dart';

/// 온보딩 알림 단계 — «허용» / «나중에» 처리.
///
/// - [deferNotificationSetupLater]: 온보딩 단계를 끝낸다. 알림을 아직 정하지
///   않았을 때만 꺼진 값을 저장하고, 이미 켠 설정은 덮어쓰지 않는다.
/// - [completeWithSystemPermissionRequest]: 시스템 권한 요청 후 결과에 따라 저장.
class NotificationOnboardingActions {
  NotificationOnboardingActions({
    NotificationPermissionService? permissionService,
  }) : _permission =
            permissionService ?? NotificationPermissionService.instance;

  final NotificationPermissionService _permission;

  /// «나중에 설정할게요» — 온보딩 단계만 끝낸다.
  ///
  /// 아직 알림을 정해 본 적이 없을 때만 꺼진 기본값을 저장한다.
  /// 안내를 다시 진행할 때 이미 켜 둔 푸시를 덮어쓰지 않기 위해서다.
  Future<void> deferNotificationSetupLater() async {
    final existing = await NotificationPreferencesStorage.load();
    final alreadyChosen = existing.notificationsEnabled ||
        existing.permissionStatus != NotificationPermissionStatus.notRequested;
    if (!alreadyChosen) {
      await NotificationPreferencesStorage.save(
        existing.copyWith(
          notificationsEnabled: false,
          permissionStatus: NotificationPermissionStatus.notRequested,
        ),
      );
    }
    await OnboardingLocalStorage.markNotificationSetupHandled();
  }

  /// «알림 허용하기» — 시스템 권한 요청 후 상태 반영.
  Future<void> completeWithSystemPermissionRequest() async {
    final existing = await NotificationPreferencesStorage.load();
    final granted = await _permission.requestPostNotificationsPermission();
    if (granted) {
      await NotificationPreferencesStorage.save(
        existing.copyWith(
          notificationsEnabled: true,
          permissionStatus: NotificationPermissionStatus.granted,
        ),
      );
    } else {
      await NotificationPreferencesStorage.save(
        existing.copyWith(
          notificationsEnabled: false,
          permissionStatus: NotificationPermissionStatus.denied,
        ),
      );
    }
    await OnboardingLocalStorage.markNotificationSetupHandled();
  }
}
