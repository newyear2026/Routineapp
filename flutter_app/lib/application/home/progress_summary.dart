import '../../domain/progress/daily_routine_progress.dart';

/// 오늘 루틴 진행 요약 — Home·헤더·Progress가 동일 기준([calculateProgress]) 사용
///
/// [HomeSnapshot.progressSummary] / [RoutineAppController.progressSummary]로 접근
class ProgressSummary {
  const ProgressSummary({
    required this.total,
    required this.completed,
    required this.remaining,
    required this.percent,
  });

  factory ProgressSummary.fromResult(DailyRoutineProgressResult r) {
    return ProgressSummary(
      total: r.total,
      completed: r.completed,
      remaining: r.remaining,
      percent: r.percent,
    );
  }

  final int total;
  final int completed;
  final int remaining;

  /// 0~100
  final int percent;

  bool get isEmptyDay => total == 0;
}
