import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/data/seed/our_apps.dart';
import 'package:routine_timer/screens/our_apps_screen.dart';

import 'support/localization.dart';

void main() {
  test('목록의 앱마다 아이콘이 있고 패키지가 겹치지 않는다', () {
    expect(ourApps, isNotEmpty);
    expect(
      ourApps.map((app) => app.packageName).toSet(),
      hasLength(ourApps.length),
    );
    for (final app in ourApps) {
      expect(File(app.icon).existsSync(), isTrue, reason: app.icon);
      expect(
        app.packageName,
        isNot('com.dayround.app'),
        reason: 'LOOPET이 자기 자신을 추천하지 않는다',
      );
    }
  });

  Future<void> pumpScreen(WidgetTester tester, ListingOpener opener) async {
    await tester.pumpWidget(
      localizedApp(home: OurAppsScreen(openListing: opener)),
    );
    await tester.pump();
  }

  testWidgets('앱마다 같은 카드와 버튼을 준다', (tester) async {
    await pumpScreen(tester, (_, {referrer}) async => true);

    for (final app in ourApps) {
      expect(find.text(app.name), findsOneWidget);
    }
    expect(find.text('Google Play에서 보기'), findsNWidgets(ourApps.length));
    expect(tester.takeException(), isNull);
  });

  testWidgets('누른 앱의 페이지를 LOOPET에서 왔다는 표시와 함께 연다', (tester) async {
    final opened = <(String, String?)>[];
    await pumpScreen(tester, (packageName, {referrer}) async {
      opened.add((packageName, referrer));
      return true;
    });

    await tester.tap(find.text('Google Play에서 보기').last);
    await tester.pump();

    expect(opened, [(ourApps.last.packageName, ourAppsReferrer)]);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Play를 열지 못하면 알린다', (tester) async {
    await pumpScreen(tester, (_, {referrer}) async => false);

    await tester.tap(find.text('Google Play에서 보기').first);
    await tester.pump();

    expect(find.text('Google Play를 열 수 없어요.'), findsOneWidget);
  });
}
