import '../../data/local/onboarding_local_storage.dart';
import '../../domain/models/routine.dart';
import '../../domain/onboarding/recommended_routine_catalog.dart';
import 'routine_data_service.dart';

/// 온보딩 «추천 루틴» 저장 — 화면은 이 서비스만 호출한다.
class OnboardingRoutineSetupService {
  OnboardingRoutineSetupService({RoutineDataService? dataService})
      : _data = dataService ?? RoutineDataService();

  final RoutineDataService _data;

  /// 선택한 추천 루틴을 반영하고 초기 루틴 설정 단계를 완료 처리한다.
  ///
  /// **이미 있는 루틴은 건드리지 않는다 — 더하기만 한다.**
  /// 예전에는 `onboarding_rec_*` 를 모두 지우고 다시 넣었다. 추천 루틴은
  /// 편집해도 id 가 그대로라(편집은 [Routine.copyWith]) 안내를 다시 진행하면
  /// 사용자가 고친 시각·제목·요일이 조용히 사라졌고, 이번에 고르지 않은
  /// 추천 루틴까지 지워졌다. 안내를 다시 보는 일이 저장된 루틴을 되돌리는
  /// 일이 되어서는 안 된다.
  ///
  /// id 가 `onboarding_rec_<catalogId>` 로 고정이라 같은 추천을 다시 골라도
  /// 중복으로 쌓이지 않는다.
  Future<void> completeWithSelectedDefinitions(
    List<RecommendedRoutineDefinition> selected,
    String Function(RecommendedRoutineDefinition) titleOf,
  ) async {
    final existing = await _data.loadRoutines();
    final existingIds = existing.map((r) => r.id).toSet();
    final created = selected
        .map((d) => d.toRoutine(titleOf(d)))
        .where((r) => !existingIds.contains(r.id))
        .toList();
    if (created.isNotEmpty) {
      await _data.saveRoutines([...existing, ...created]);
    }
    await OnboardingLocalStorage.markInitialRoutineSetupCompleted();
  }

  /// 루틴은 저장하지 않고 초기 루틴 설정 단계만 완료 처리한다.
  Future<void> skipWithoutSavingRoutines() async {
    await OnboardingLocalStorage.markInitialRoutineSetupCompleted();
  }
}
