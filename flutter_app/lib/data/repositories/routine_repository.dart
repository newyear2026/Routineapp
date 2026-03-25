import '../../domain/models/routine.dart';

/// 루틴 **정의**만 저장 — 로그는 [RoutineLogRepository]
abstract class RoutineRepository {
  Future<List<Routine>> loadRoutines();

  Future<void> saveRoutines(List<Routine> routines);

  /// 목록 끝에 추가 후 저장 (신규 생성)
  Future<void> addRoutine(Routine routine);

  /// id가 있으면 교체, 없으면 추가
  Future<void> upsertRoutine(Routine routine);
}
