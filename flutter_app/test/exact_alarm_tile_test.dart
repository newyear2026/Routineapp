import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/services/exact_alarm_service.dart';
import 'package:routine_timer/l10n/app_localizations.dart';
import 'package:routine_timer/widgets/settings/exact_alarm_tile.dart';

void main() {
  Future<void> pumpTile(
    WidgetTester tester, {
    required ExactAlarmService service,
    ValueChanged<bool>? onChanged,
    Locale locale = const Locale('ko'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ExactAlarmTile(service: service, onChanged: onChanged),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // 같은 테스트에서 두 번 pump 하면 State 가 재사용돼 initState 가 다시 돌지 않는다.
  testWidgets('권한이 있으면 켜짐으로 보인다', (tester) async {
    await pumpTile(tester, service: _FakeExactAlarmService(allowed: true));
    expect(find.text('켜짐'), findsOneWidget);
    expect(find.text('설정한 시각에 정확히 울려요'), findsOneWidget);
  });

  testWidgets('권한이 없으면 꺼짐과 지연 안내로 보인다', (tester) async {
    await pumpTile(tester, service: _FakeExactAlarmService(allowed: false));
    expect(find.text('꺼짐'), findsOneWidget);
    expect(find.text('알림이 몇 분 늦게 올 수 있어요'), findsOneWidget);
  });

  testWidgets('눌러서 시스템 설정으로 보낸다 — 앱이 직접 켤 수 없는 권한이다', (tester) async {
    final service = _FakeExactAlarmService(allowed: false);
    await pumpTile(tester, service: service);

    await tester.tap(find.byKey(const Key('exact-alarm-tile')));
    await tester.pumpAndSettle();

    expect(service.openCount, 1);
  });

  testWidgets('설정을 다녀와 권한이 바뀌면 알림 재예약을 알린다', (tester) async {
    // 예약된 알람은 예약 시점의 모드를 들고 있어, 다시 걸지 않으면 반영되지 않는다.
    final service = _FakeExactAlarmService(allowed: false);
    final changes = <bool>[];
    await pumpTile(tester, service: service, onChanged: changes.add);

    // 첫 조회는 «변경»이 아니다.
    expect(changes, isEmpty);

    service.allowed = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(changes, [true]);
    expect(find.text('켜짐'), findsOneWidget);
  });

  testWidgets('권한이 그대로면 재예약을 알리지 않는다', (tester) async {
    final service = _FakeExactAlarmService(allowed: false);
    final changes = <bool>[];
    await pumpTile(tester, service: service, onChanged: changes.add);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
  });
}

class _FakeExactAlarmService implements ExactAlarmService {
  _FakeExactAlarmService({required this.allowed});

  bool allowed;
  int openCount = 0;

  @override
  Future<bool> canScheduleExactAlarms() async => allowed;

  @override
  Future<void> openSettings() async => openCount++;
}
