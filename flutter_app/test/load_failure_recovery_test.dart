import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/data/repositories/routine_repository.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/localization.dart';
import 'support/test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const homeWidgetChannel = MethodChannel('home_widget');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, (call) async => true);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, null);
  });

  RoutineAppController controllerOn(_CorruptRoutineRepository repo) {
    return RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: repo,
        logRepository: MemoryLogRepository(),
      ),
      notificationService: RoutineNotificationService(
        exactAlarmsAllowed: () async => false,
        gateway: NoopNotificationGateway(),
        preferencesLoader: () async =>
            NotificationPreferences.firstLaunchDefaults,
      ),
      nowProvider: () => DateTime(2026, 4, 9, 7, 30),
      clockAutoRefreshEnabled: false,
    );
  }

  group('로드 실패 복구', () {
    test('저장소가 터져도 예외를 밖으로 던지지 않는다', () async {
      // main 의 `..load()` 는 fire-and-forget 이라, 던지면 아무도 받지 못한다.
      final controller = controllerOn(_CorruptRoutineRepository());
      addTearDown(controller.dispose);

      await expectLater(controller.load(), completes);
    });

    test('로드가 실패하면 로딩이 아니라 복구 상태가 된다', () async {
      final repo = _CorruptRoutineRepository();
      final controller = controllerOn(repo);
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.isLoaded, isFalse);
      expect(controller.hasBlockingLoadError, isTrue);
    });

    test('실패해도 저장소에 쓰지 않는다', () async {
      // 깨진 데이터라도 원본이 남아야 나중에 손볼 수 있다. 빈 값으로
      // 덮어쓰면 그 길이 사라진다.
      final repo = _CorruptRoutineRepository();
      final controller = controllerOn(repo);
      addTearDown(controller.dispose);

      await controller.load();

      expect(repo.writes, 0);
    });

    test('다시 시도해서 회복하면 복구 상태가 풀린다', () async {
      final repo = _CorruptRoutineRepository();
      final controller = controllerOn(repo);
      addTearDown(controller.dispose);

      await controller.load();
      expect(controller.hasBlockingLoadError, isTrue);

      repo.healthy = true;
      await controller.load();

      expect(controller.hasBlockingLoadError, isFalse);
      expect(controller.isLoaded, isTrue);
      expect(controller.routines, hasLength(1));
    });

    test('이미 불러온 뒤의 실패는 화면을 비우지 않는다', () async {
      // 저장 뒤 다시 부른 로드가 실패한 경우다. 조금 낡았어도 있는 것을
      // 계속 보여 주는 편이 낫다.
      final repo = _CorruptRoutineRepository(healthy: true);
      final controller = controllerOn(repo);
      addTearDown(controller.dispose);

      await controller.load();
      expect(controller.isLoaded, isTrue);

      repo.healthy = false;
      await controller.load();

      expect(controller.hasBlockingLoadError, isFalse);
      expect(controller.routines, hasLength(1));
    });

    testWidgets('복구 화면은 무한 로딩 대신 다시 시도를 준다', (tester) async {
      final repo = _CorruptRoutineRepository();
      final controller = controllerOn(repo);
      addTearDown(controller.dispose);
      await controller.load();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: localizedApp(home: const HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('정보를 불러오지 못했어요'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('load-failure-retry')), findsOneWidget);
    });

    testWidgets('다시 시도가 성공하면 화면이 돌아온다', (tester) async {
      final repo = _CorruptRoutineRepository();
      final controller = controllerOn(repo);
      addTearDown(controller.dispose);
      await controller.load();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: localizedApp(home: const HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      repo.healthy = true;
      await tester.tap(find.byKey(const Key('load-failure-retry')));
      await tester.pumpAndSettle();

      expect(find.text('정보를 불러오지 못했어요'), findsNothing);
      expect(find.text('기상'), findsWidgets);
    });
  });
}

/// 저장된 JSON 이 깨진 상황을 재현한다.
///
/// `LocalRoutineRepository` 는 `jsonDecode` 결과를 그대로 캐스팅하므로
/// 값이 깨지면 여기처럼 예외가 그대로 올라온다.
class _CorruptRoutineRepository implements RoutineRepository {
  _CorruptRoutineRepository({this.healthy = false});

  /// 다시 시도했을 때 성공시킬지 — 복구 경로를 확인한다.
  bool healthy;

  /// 실패 경로가 저장소를 건드리지 않는지 본다.
  int writes = 0;

  @override
  Future<List<Routine>> loadRoutines() async {
    if (!healthy) throw const FormatException('corrupt routine json');
    return [dailyRoutine(id: 'wake', title: '기상', startHour: 7, endHour: 8)];
  }

  @override
  Future<void> saveRoutines(List<Routine> routines) async => writes++;

  @override
  Future<void> addRoutine(Routine routine) async => writes++;

  @override
  Future<void> upsertRoutine(Routine routine) async => writes++;

  @override
  Future<void> deleteRoutine(String routineId) async => writes++;
}
