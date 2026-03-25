enum RoutineActionSource {
  /// 앱 내 버튼(완료·나중에·스킵 등)
  app,
  user,
  system,
  notification,
}

extension RoutineActionSourceSerialization on RoutineActionSource {
  String get storageKey {
    switch (this) {
      case RoutineActionSource.app:
        return 'app';
      case RoutineActionSource.user:
        return 'user';
      case RoutineActionSource.system:
        return 'system';
      case RoutineActionSource.notification:
        return 'notification';
    }
  }
}

RoutineActionSource? parseRoutineActionSource(String? raw) {
  if (raw == null) return null;
  switch (raw) {
    case 'app':
      return RoutineActionSource.app;
    case 'user':
      return RoutineActionSource.user;
    case 'system':
      return RoutineActionSource.system;
    case 'notification':
      return RoutineActionSource.notification;
    default:
      return null;
  }
}
