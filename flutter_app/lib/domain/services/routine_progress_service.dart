import '../models/routine.dart';
import '../models/routine_log.dart';
import '../progress/daily_progress_calculator.dart';
import 'routine_occurrences.dart';

/// 일일 진행률·창구 내 진행률 — 로그와 루틴 정의만으로 계산
class RoutineProgressService {
  const RoutineProgressService();

  /// 오늘 루틴 수 대비 완료 수 — [DailyProgressCalculator.calculateProgress] 위임
  ({int completed, int total}) todayCompletionProgress(
    List<Routine> todaysSorted,
    List<RoutineLog> logsToday,
  ) {
    final r = DailyProgressCalculator.calculateProgress(
      todaysSorted,
      logsToday,
    );
    return (completed: r.completed, total: r.total);
  }

  /// 현재 루틴 시간 창 안에서의 경과 0~100%
  int progressPercentInWindow(Routine r, DateTime nowLocal) {
    final w = RoutineOccurrences.window(r, nowLocal);
    final duration = w.end.difference(w.start).inMilliseconds;
    if (duration <= 0) return 0;
    return (100 * nowLocal.difference(w.start).inMilliseconds / duration)
        .round()
        .clamp(0, 100);
  }
}
