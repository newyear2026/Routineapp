/// 루틴 로그 상태 — 로컬/원격 저장 시 문자열로 직렬화
enum RoutineLogStatus {
  scheduled,
  active,
  completed,
  snoozed,
  skipped,
  noResponse,
  expired,
}

extension RoutineLogStatusSerialization on RoutineLogStatus {
  String get storageKey {
    switch (this) {
      case RoutineLogStatus.scheduled:
        return 'scheduled';
      case RoutineLogStatus.active:
        return 'active';
      case RoutineLogStatus.completed:
        return 'completed';
      case RoutineLogStatus.snoozed:
        return 'snoozed';
      case RoutineLogStatus.skipped:
        return 'skipped';
      case RoutineLogStatus.noResponse:
        return 'no_response';
      case RoutineLogStatus.expired:
        return 'expired';
    }
  }
}

RoutineLogStatus parseRoutineLogStatus(String raw) {
  switch (raw) {
    case 'scheduled':
      return RoutineLogStatus.scheduled;
    case 'active':
      return RoutineLogStatus.active;
    case 'completed':
      return RoutineLogStatus.completed;
    case 'snoozed':
      return RoutineLogStatus.snoozed;
    case 'skipped':
      return RoutineLogStatus.skipped;
    case 'no_response':
      return RoutineLogStatus.noResponse;
    case 'expired':
      return RoutineLogStatus.expired;
    default:
      return RoutineLogStatus.scheduled;
  }
}
