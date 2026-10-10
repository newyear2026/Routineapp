import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/services/onboarding_routine_setup_service.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/domain/onboarding/recommended_routine_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  RecommendedRoutineDefinition definitionOf(String catalogId) =>
      RecommendedRoutineCatalog.items
          .firstWhere((d) => d.catalogId == catalogId);

  ({OnboardingRoutineSetupService service, MemoryRoutineRepository repo})
      makeService([List<dynamic> initial = const []]) {
    final repo = MemoryRoutineRepository(List.of(initial.cast()));
    final service = OnboardingRoutineSetupService(
      dataService: RoutineDataService(routineRepository: repo),
    );
    return (service: service, repo: repo);
  }

  Future<void> complete(
    OnboardingRoutineSetupService service,
    List<String> catalogIds,
  ) =>
      service.completeWithSelectedDefinitions(
        catalogIds.map(definitionOf).toList(),
        (d) => d.catalogId,
      );

  group('온보딩 추천 루틴 저장', () {
    test('처음 진행하면 고른 추천 루틴을 저장한다', () async {
      final s = makeService();

      await complete(s.service, ['wake', 'sleep']);

      expect(
        s.repo.items.map((r) => r.id),
        containsAll(['onboarding_rec_wake', 'onboarding_rec_sleep']),
      );
      expect(s.repo.items, hasLength(2));
    });

    test('다시 진행해도 사용자가 고친 추천 루틴을 되돌리지 않는다', () async {
      final s = makeService();
      await complete(s.service, ['wake']);

      // 사용자가 시각과 이름을 고친다. 편집은 copyWith 라 id 가 그대로다.
      final edited = s.repo.items.single.copyWith(
        title: '아주 일찍 기상',
        startMinutesFromMidnight: 5 * 60,
      );
      await s.repo.upsertRoutine(edited);

      await complete(s.service, ['wake']);

      final saved = s.repo.items.singleWhere(
        (r) => r.id == 'onboarding_rec_wake',
      );
      expect(saved.title, '아주 일찍 기상');
      expect(saved.startMinutesFromMidnight, 5 * 60);
    });

    test('다시 진행할 때 고르지 않은 추천 루틴도 남는다', () async {
      final s = makeService();
      await complete(s.service, ['wake', 'sleep']);

      await complete(s.service, ['wake']);

      expect(
        s.repo.items.map((r) => r.id),
        containsAll(['onboarding_rec_wake', 'onboarding_rec_sleep']),
      );
    });

    test('같은 추천을 다시 골라도 중복으로 쌓이지 않는다', () async {
      final s = makeService();

      await complete(s.service, ['wake']);
      await complete(s.service, ['wake']);

      expect(
        s.repo.items.where((r) => r.id == 'onboarding_rec_wake'),
        hasLength(1),
      );
    });

    test('사용자가 직접 만든 루틴은 건드리지 않는다', () async {
      final mine = dailyRoutine(
        id: 'mine',
        title: '내 루틴',
        startHour: 9,
        endHour: 10,
      );
      final s = makeService([mine]);

      await complete(s.service, ['wake']);

      expect(s.repo.items.map((r) => r.id), contains('mine'));
      expect(
        s.repo.items.singleWhere((r) => r.id == 'mine').title,
        '내 루틴',
      );
    });

    test('건너뛰면 루틴을 저장하지 않는다', () async {
      final s = makeService();

      await s.service.skipWithoutSavingRoutines();

      expect(s.repo.items, isEmpty);
    });
  });
}
