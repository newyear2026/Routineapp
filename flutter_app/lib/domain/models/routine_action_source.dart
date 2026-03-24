enum RoutineActionSource {
  user,
  system,
  notification,
}

extension RoutineActionSourceSerialization on RoutineActionSource {
  String get storageKey {
    switch (this) {
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
