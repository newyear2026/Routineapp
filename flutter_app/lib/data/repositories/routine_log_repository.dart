import '../../domain/models/routine_log.dart';

/// 루틴 **실행 로그**만 저장 — [Routine] 정의와 분리
abstract class RoutineLogRepository {
  Future<List<RoutineLog>> loadLogsForDate(DateTime dateLocal);

  Future<void> upsertLog(RoutineLog log);

  /// 마이그레이션·백업·동기화용
  Future<List<RoutineLog>> loadAllLogs();
}
