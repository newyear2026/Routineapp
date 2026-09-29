import '../domain/models/routine_write_error.dart';

/// [RoutineAppController.saveRoutine] 등 저장 연산 결과
class RoutineSaveResult {
  const RoutineSaveResult._({required this.ok, this.error});

  final bool ok;

  /// 실패 종류. 성공이면 null이다. 표시 문장은 화면에서 만든다.
  final RoutineWriteError? error;

  static const RoutineSaveResult success = RoutineSaveResult._(ok: true);

  factory RoutineSaveResult.failure(RoutineWriteError error) =>
      RoutineSaveResult._(ok: false, error: error);
}
