import '../data/repositories/routine_log_repository.dart';
import '../data/repositories/routine_repository.dart';
import '../domain/models/routine_action_source.dart';
import '../domain/services/routine_log_action_service.dart';
import '../domain/services/routine_occurrences.dart';
import '../domain/services/routine_state_resolver.dart';
import 'widget_routine_target.dart';

class WidgetCompletionService {
  const WidgetCompletionService({required this.routines, required this.logs});
  final RoutineRepository routines;
  final RoutineLogRepository logs;

  Future<bool> complete(Uri? uri, DateTime now) async {
    final target = WidgetRoutineTarget.parse(uri);
    if (target == null) return false;
    final date = DateTime.parse(target.dateYmd);
    final definition =
        (await routines.loadRoutines()).where(target.matches).firstOrNull;
    if (definition == null ||
        !definition.repeatWeekdays.contains(date.weekday)) {
      return false;
    }
    final routine = RoutineOccurrences.onDate(definition, date);
    final existing = (await logs.loadLogsForDate(date))
        .where((log) => log.routineId == routine.id)
        .firstOrNull;
    if (!RoutineStateResolver.canApplyUserAction(
        routine: routine, log: existing, nowLocal: now)) {
      return false;
    }
    final outcome = RoutineLogActionService.complete(
      routine: routine,
      dateYmd: target.dateYmd,
      existing: existing,
      nowLocal: now,
      source: RoutineActionSource.widget,
    );
    return outcome.shouldPersist &&
        await logs.saveWidgetCompletion(outcome.log);
  }
}
