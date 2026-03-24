import 'routine_action_source.dart';
import 'routine_log_status.dart';

/// 특정 날짜의 루틴 실행 기록 — **실제 상태는 항상 로그 기준**
class RoutineLog {
  const RoutineLog({
    required this.id,
    required this.routineId,
    required this.dateYmd,
    required this.status,
    this.completedAtMs,
    this.snoozedUntilMs,
    this.skippedAtMs,
    this.actionSource,
  });

  /// `routineId` + `dateYmd` 조합 등 유니크 키 권장
  final String id;
  final String routineId;

  /// `yyyy-MM-dd` (로컬 날짜)
  final String dateYmd;
  final RoutineLogStatus status;

  final int? completedAtMs;

  /// 재알림 스케줄용 — 알림 모듈이 이 시각 이후에 다시 울리면 됨
  final int? snoozedUntilMs;

  /// 스킵 시각
  final int? skippedAtMs;
  final RoutineActionSource? actionSource;

  Map<String, dynamic> toJson() => {
        'id': id,
        'routineId': routineId,
        'dateYmd': dateYmd,
        'status': status.storageKey,
        'completedAtMs': completedAtMs,
        'snoozedUntilMs': snoozedUntilMs,
        'skippedAtMs': skippedAtMs,
        'actionSource': actionSource?.storageKey,
      };

  factory RoutineLog.fromJson(Map<String, dynamic> json) {
    return RoutineLog(
      id: json['id'] as String,
      routineId: json['routineId'] as String,
      dateYmd: json['dateYmd'] as String,
      status: parseRoutineLogStatus(json['status'] as String),
      completedAtMs: json['completedAtMs'] as int?,
      snoozedUntilMs: json['snoozedUntilMs'] as int?,
      skippedAtMs: json['skippedAtMs'] as int?,
      actionSource: parseRoutineActionSource(json['actionSource'] as String?),
    );
  }

  RoutineLog copyWith({
    String? id,
    String? routineId,
    String? dateYmd,
    RoutineLogStatus? status,
    int? completedAtMs,
    int? snoozedUntilMs,
    int? skippedAtMs,
    RoutineActionSource? actionSource,
  }) {
    return RoutineLog(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      dateYmd: dateYmd ?? this.dateYmd,
      status: status ?? this.status,
      completedAtMs: completedAtMs ?? this.completedAtMs,
      snoozedUntilMs: snoozedUntilMs ?? this.snoozedUntilMs,
      skippedAtMs: skippedAtMs ?? this.skippedAtMs,
      actionSource: actionSource ?? this.actionSource,
    );
  }
}
