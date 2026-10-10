import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/data/repositories/routine_log_repository.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_doubles.dart';

/// 테스트 그룹의 main/group에서 호출한다. 각 테스트의 저장값과 채널을 초기화한다.
void setUpRoutineTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('home_widget');
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => true);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  });
}

/// 화면 테스트용 컨트롤러. 호출자가 load와 dispose 시점을 관리한다.
///
/// 고정 시각, 메모리 저장소, 알림 대역, 즉시 완료되는 진동 콜백을 사용한다.
/// 진동/시계/플랫폼 연동 자체를 검증하는 테스트는 실제 생성자를 직접 사용한다.
RoutineAppController createTestRoutineController({
  required DateTime now,
  List<Routine> routines = const [],
  RoutineLogRepository? logRepository,
  RoutineNotificationService? notificationService,
}) {
  return RoutineAppController(
    dataService: RoutineDataService(
      routineRepository: MemoryRoutineRepository(routines),
      logRepository: logRepository ?? MemoryLogRepository(),
    ),
    notificationService: notificationService ??
        RoutineNotificationService(
          gateway: NoopNotificationGateway(),
          exactAlarmsAllowed: () async => false,
          preferencesLoader: () async =>
              NotificationPreferences.firstLaunchDefaults,
        ),
    completionHaptic: () async {},
    nowProvider: () => now,
    clockAutoRefreshEnabled: false,
  );
}
