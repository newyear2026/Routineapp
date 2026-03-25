import '../models/routine.dart';
import '../models/routine_log.dart';
import '../models/routine_action_source.dart';
import '../models/routine_log_status.dart';

/// 루틴 로그 생성/갱신 — **정의(Routine)는 건드리지 않고** 로그만 다룬다.
abstract final class RoutineLogActionService {
  static const defaultSnooze = Duration(minutes: 15);

  /// 완료 — 이미 완료면 동일 로그 반환 + [RoutineLogApplyOutcome.shouldPersist] = false
  static RoutineLogApplyOutcome complete({
    required Routine routine,
    required String dateYmd,
    required RoutineLog? existing,
    required DateTime nowLocal,
    RoutineActionSource source = RoutineActionSource.app,
  }) {
    final ts = nowLocal.millisecondsSinceEpoch;
    final id = '${routine.id}_$dateYmd';

    if (existing != null) {
      if (existing.status == RoutineLogStatus.completed) {
        return RoutineLogApplyOutcome(
          log: existing,
          shouldPersist: false,
          reason: 'already_completed',
        );
      }
      if (existing.status == RoutineLogStatus.skipped) {
        return RoutineLogApplyOutcome(
          log: existing,
          shouldPersist: false,
          reason: 'blocked_after_skip',
        );
      }
    }

    final log = RoutineLog(
      id: id,
      routineId: routine.id,
      dateYmd: dateYmd,
      status: RoutineLogStatus.completed,
      completedAtMs: ts,
      snoozedUntilMs: null,
      skippedAtMs: null,
      actionSource: source,
    );
    return RoutineLogApplyOutcome(log: log, shouldPersist: true);
  }

  /// 나중에 — 스누즈 만료 시각 갱신, 재알림 스케줄링은 상위(알림 모듈)에서 [snoozedUntilMs] 사용
  static RoutineLogApplyOutcome snooze({
    required Routine routine,
    required String dateYmd,
    required RoutineLog? existing,
    required DateTime nowLocal,
    Duration delay = defaultSnooze,
    RoutineActionSource source = RoutineActionSource.app,
  }) {
    final until = nowLocal.add(delay).millisecondsSinceEpoch;
    final id = '${routine.id}_$dateYmd';

    if (existing != null) {
      if (existing.status == RoutineLogStatus.completed ||
          existing.status == RoutineLogStatus.skipped) {
        return RoutineLogApplyOutcome(
          log: existing,
          shouldPersist: false,
          reason: 'terminal_state',
        );
      }
    }

    final log = RoutineLog(
      id: id,
      routineId: routine.id,
      dateYmd: dateYmd,
      status: RoutineLogStatus.snoozed,
      completedAtMs: existing?.completedAtMs,
      snoozedUntilMs: until,
      skippedAtMs: null,
      actionSource: source,
    );
    return RoutineLogApplyOutcome(log: log, shouldPersist: true);
  }

  /// 스킵
  static RoutineLogApplyOutcome skip({
    required Routine routine,
    required String dateYmd,
    required RoutineLog? existing,
    required DateTime nowLocal,
    RoutineActionSource source = RoutineActionSource.app,
  }) {
    final ts = nowLocal.millisecondsSinceEpoch;
    final id = '${routine.id}_$dateYmd';

    if (existing != null) {
      if (existing.status == RoutineLogStatus.skipped) {
        return RoutineLogApplyOutcome(
          log: existing,
          shouldPersist: false,
          reason: 'already_skipped',
        );
      }
      if (existing.status == RoutineLogStatus.completed) {
        return RoutineLogApplyOutcome(
          log: existing,
          shouldPersist: false,
          reason: 'blocked_after_complete',
        );
      }
    }

    final log = RoutineLog(
      id: id,
      routineId: routine.id,
      dateYmd: dateYmd,
      status: RoutineLogStatus.skipped,
      completedAtMs: null,
      snoozedUntilMs: null,
      skippedAtMs: ts,
      actionSource: source,
    );
    return RoutineLogApplyOutcome(log: log, shouldPersist: true);
  }
}

/// [RoutineLogActionService] 호출 결과 — 저장소에 쓸지 여부
class RoutineLogApplyOutcome {
  const RoutineLogApplyOutcome({
    required this.log,
    required this.shouldPersist,
    this.reason,
  });

  final RoutineLog log;
  final bool shouldPersist;

  /// 디버그·로깅용: `already_completed`, `blocked_after_skip` 등
  final String? reason;
}
