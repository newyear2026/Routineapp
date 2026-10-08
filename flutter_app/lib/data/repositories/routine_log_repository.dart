import '../../domain/models/routine_log.dart';

/// 루틴 **실행 로그**만 저장 — [Routine] 정의와 분리
abstract class RoutineLogRepository {
  Future<List<RoutineLog>> loadLogsForDate(DateTime dateLocal);

  /// 동일 [RoutineLog.id]가 있으면 갱신 — 하루·루틴당 하나(`routineId_dateYmd`)
  Future<void> upsertLog(RoutineLog log);

  /// 알림의 «나중에» 기록을 조건부로 저장한다.
  ///
  /// 같은 루틴·날짜의 완료/스킵 기록이나 같거나 더 늦은 미루기 기록은
  /// 덮어쓰지 않고 false를 반환한다. 여러 실행 주체가 저장하는 구현에서는
  /// 조건 확인과 쓰기를 하나의 원자적 작업으로 처리해야 한다.
  Future<bool> saveNotificationSnooze(RoutineLog log);

  /// Atomically preserve an existing completed/skipped record on repeated taps.
  Future<bool> saveWidgetCompletion(RoutineLog log);

  /// 마이그레이션·백업·동기화용
  Future<List<RoutineLog>> loadAllLogs();

  /// 루틴 삭제 시 연결된 로그 정리
  Future<void> deleteLogsForRoutine(String routineId);

  /// 특정 날짜의 실행 기록을 되돌릴 때 사용한다.
  Future<void> deleteLogForRoutineOnDate(String routineId, String dateYmd);
}
