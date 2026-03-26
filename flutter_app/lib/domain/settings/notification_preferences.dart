import 'notification_permission_status.dart';

/// 앱 수준 알림 설정 — [NotificationPreferencesStorage]와 1:1.
class NotificationPreferences {
  const NotificationPreferences({
    required this.notificationsEnabled,
    required this.permissionStatus,
    required this.soundEnabled,
  });

  /// 앱에서 푸시(로컬 알림) 사용 여부 — OS 권한과 별도로 사용자 의사.
  final bool notificationsEnabled;
  final NotificationPermissionStatus permissionStatus;
  final bool soundEnabled;

  static const firstLaunchDefaults = NotificationPreferences(
    notificationsEnabled: false,
    permissionStatus: NotificationPermissionStatus.notRequested,
    soundEnabled: true,
  );

  NotificationPreferences copyWith({
    bool? notificationsEnabled,
    NotificationPermissionStatus? permissionStatus,
    bool? soundEnabled,
  }) {
    return NotificationPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}
