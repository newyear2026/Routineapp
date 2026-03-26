/// OS 알림 권한·노출 상태 (앱 설정과 별개로 저장).
enum NotificationPermissionStatus {
  /// 시스템 권한 대화를 아직 띄우지 않음 (온보딩 «나중에» 등).
  notRequested,

  /// 사용자가 시스템에서 거절.
  denied,

  /// 게시 가능한 수준으로 허용됨.
  granted,
}

extension NotificationPermissionStatusStorage on NotificationPermissionStatus {
  static NotificationPermissionStatus fromRaw(String? raw) {
    switch (raw) {
      case 'denied':
        return NotificationPermissionStatus.denied;
      case 'granted':
        return NotificationPermissionStatus.granted;
      case 'not_requested':
      default:
        return NotificationPermissionStatus.notRequested;
    }
  }

  String get toRaw {
    switch (this) {
      case NotificationPermissionStatus.notRequested:
        return 'not_requested';
      case NotificationPermissionStatus.denied:
        return 'denied';
      case NotificationPermissionStatus.granted:
        return 'granted';
    }
  }
}
