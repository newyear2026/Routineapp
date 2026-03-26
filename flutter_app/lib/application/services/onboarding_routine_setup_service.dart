import '../../data/local/onboarding_local_storage.dart';
import '../../domain/models/routine.dart';
import '../../domain/onboarding/recommended_routine_catalog.dart';
import 'routine_data_service.dart';

/// 온보딩 «추천 루틴» 저장 — 화면은 이 서비스만 호출한다.
class OnboardingRoutineSetupService {
  OnboardingRoutineSetupService({RoutineDataService? dataService})
      : _data = dataService ?? RoutineDataService();

  final RoutineDataService _data;

  static bool _isOnboardingRecommendedRoutine(Routine r) =>
      r.id.startsWith('onboarding_rec_');

  /// 선택한 추천 루틴을 반영하고 초기 루틴 설정 단계를 완료 처리한다.
  /// 이전에 저장된 `onboarding_rec_*` 루틴은 제거 후 재삽입한다.
  Future<void> completeWithSelectedDefinitions(
    List<RecommendedRoutineDefinition> selected,
  ) async {
    final existing = await _data.loadRoutines();
    final kept =
        existing.where((r) => !_isOnboardingRecommendedRoutine(r)).toList();
    final created = selected.map((d) => d.toRoutine()).toList();
    await _data.saveRoutines([...kept, ...created]);
    await OnboardingLocalStorage.markInitialRoutineSetupCompleted();
  }

  /// 루틴은 저장하지 않고 초기 루틴 설정 단계만 완료 처리한다.
  Future<void> skipWithoutSavingRoutines() async {
    await OnboardingLocalStorage.markInitialRoutineSetupCompleted();
  }
}
