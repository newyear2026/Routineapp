import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/widgets/ads/home_upcoming_ad_card.dart';

/// 광고를 띄울 수 없는 환경에서 이 위젯이 «없는 것처럼» 굴어야 한다.
///
/// 테스트 환경은 Android가 아니므로 `AdConfig.isPlatformSupported`가 false다.
/// SDK를 올리지 않고, 광고를 요청하지 않고, 자리도 차지하지 않는 게 맞다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Size> pumpCard(WidgetTester tester, {required int upcomingCount}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const Text('앞 카드'),
              HomeUpcomingAdCard(upcomingCount: upcomingCount),
              const Text('뒤 요소'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.getSize(find.byType(HomeUpcomingAdCard));
  }

  testWidgets('광고를 못 띄우면 높이 0이다', (tester) async {
    // 자리표시자를 두면 광고가 안 나오는 날 빈 칸이 보이고,
    // 사용자는 그걸 고장으로 읽는다.
    final size = await pumpCard(tester, upcomingCount: 3);
    expect(size.height, 0);
  });

  testWidgets('다음 일정이 비어도 레이아웃을 밀지 않는다', (tester) async {
    final size = await pumpCard(tester, upcomingCount: 0);
    expect(size.height, 0);
  });

  testWidgets('광고가 없어도 앞뒤 요소는 그대로 그려진다', (tester) async {
    await pumpCard(tester, upcomingCount: 3);
    expect(find.text('앞 카드'), findsOneWidget);
    expect(find.text('뒤 요소'), findsOneWidget);
  });

  testWidgets('광고를 요청하지 않으므로 예외가 나지 않는다', (tester) async {
    // SharedPreferences 목을 깔지 않았다. 정책 판정까지 갔다면 저장소를
    // 건드려 여기서 터진다 — 플랫폼 게이트가 그 앞에서 멈춰야 한다.
    await pumpCard(tester, upcomingCount: 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('«다음 일정»이 채워지면 재시도 경로를 탄다 — 터지지 않는다', (tester) async {
    // 0으로 마운트되면 정책이 slotCondition 으로 막는다. initState 는 다시
    // 돌지 않으므로 didUpdateWidget 이 그 순간을 잡아야 자리가 죽지 않는다.
    //
    // 테스트 환경은 플랫폼 게이트에 먼저 걸려 광고까지 가지 않는다. 그래서
    // 여기서 확인할 수 있는 건 «새로 생긴 재시도 경로가 실제로 돌고, 돌면서
    // 터지지 않는다»까지다. 띄운 뒤의 동작은 실기기에서 본다.
    await pumpCard(tester, upcomingCount: 0);
    final size = await pumpCard(tester, upcomingCount: 3);

    expect(size.height, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('목록이 비었다 채워져도 자리를 차지하지 않는다', (tester) async {
    // 3 → 0 → 3. 조건이 오르내려도 재진입 방지가 풀리지 않아야 한다.
    await pumpCard(tester, upcomingCount: 3);
    await pumpCard(tester, upcomingCount: 0);
    final size = await pumpCard(tester, upcomingCount: 3);

    expect(size.height, 0);
    expect(tester.takeException(), isNull);
  });
}
