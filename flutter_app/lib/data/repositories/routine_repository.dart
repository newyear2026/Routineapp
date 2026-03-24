import '../../domain/models/routine.dart';

/// 루틴 **정의**만 저장 — 로그는 [RoutineLogRepository]
abstract class RoutineRepository {
  Future<List<Routine>> loadRoutines();

  Future<void> saveRoutines(List<Routine> routines);
}
