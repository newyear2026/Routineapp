/// [RoutineAppController.saveRoutine] 등 저장 연산 결과
class RoutineSaveResult {
  const RoutineSaveResult._({required this.ok, this.errorMessage});

  final bool ok;
  final String? errorMessage;

  static const RoutineSaveResult success = RoutineSaveResult._(ok: true);

  factory RoutineSaveResult.failure(String message) =>
      RoutineSaveResult._(ok: false, errorMessage: message);
}
