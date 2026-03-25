import '../../data/local/local_routine_log_repository.dart';
import '../../data/local/local_routine_repository.dart';
import '../../data/repositories/routine_log_repository.dart';
import '../../data/repositories/routine_repository.dart';
import '../../domain/models/routine.dart';
import '../../domain/models/routine_log.dart';

/// UI·컨트롤러는 저장 구현(SharedPreferences 등)에 직접 의존하지 않고
/// 이 서비스(또는 개별 Repository 인터페이스)만 사용한다.
///
/// 원격 동기화 시: [RoutineRepository] / [RoutineLogRepository] 구현체만 교체.
class RoutineDataService {
  RoutineDataService({
    RoutineRepository? routineRepository,
    RoutineLogRepository? logRepository,
  })  : _routines = routineRepository ?? LocalRoutineRepository.instance,
        _logs = logRepository ?? LocalRoutineLogRepository.instance;

  final RoutineRepository _routines;
  final RoutineLogRepository _logs;

  Future<List<Routine>> loadRoutines() => _routines.loadRoutines();

  Future<void> saveRoutines(List<Routine> routines) =>
      _routines.saveRoutines(routines);

  Future<void> addRoutine(Routine routine) => _routines.addRoutine(routine);

  Future<void> upsertRoutine(Routine routine) => _routines.upsertRoutine(routine);

  Future<List<RoutineLog>> loadLogsForDate(DateTime dateLocal) =>
      _logs.loadLogsForDate(dateLocal);

  Future<void> upsertLog(RoutineLog log) => _logs.upsertLog(log);
}
