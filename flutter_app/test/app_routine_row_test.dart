import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/widgets/ds/ds.dart';
import 'support/localization.dart';

/// 루틴 한 줄은 화면마다 다시 만들지 않는다.
///
/// 예전에는 홈·목록·캘린더·진행이 각자 private 위젯을 들고 있었고
/// 서피스·라운드·정보 순서가 제각각이었다.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      localizedApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('이름이 먼저, 보조 정보가 아래', (tester) async {
    await pump(
      tester,
      const AppRoutineRow(
        color: Colors.red,
        title: '아침 산책',
        subtitle: '07:00–08:00 · 매일',
      ),
    );

    final titleY = tester.getTopLeft(find.text('아침 산책')).dy;
    final subtitleY = tester.getTopLeft(find.text('07:00–08:00 · 매일')).dy;
    expect(titleY, lessThan(subtitleY), reason: '홈만 시각이 이름 위에 있었다');
  });

  testWidgets('누를 수 있으면 chevron이 자동으로 붙는다', (tester) async {
    // 홈의 다음 일정 타일은 탭하면 편집으로 가는데 단서가 없었다.
    await pump(
      tester,
      AppRoutineRow(color: Colors.red, title: '아침 산책', onTap: () {}),
    );

    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });

  testWidgets('누를 수 없으면 chevron을 붙이지 않는다', (tester) async {
    await pump(
      tester,
      const AppRoutineRow(color: Colors.red, title: '아침 산책'),
    );

    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets('trailing을 주면 chevron 대신 그것을 쓴다', (tester) async {
    await pump(
      tester,
      AppRoutineRow(
        color: Colors.red,
        title: '아침 산책',
        trailing: const Text('완료'),
        onTap: () {},
      ),
    );

    expect(find.text('완료'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets('화면들이 각자 루틴 줄을 다시 만들지 않는다', (tester) async {
    // 통합 전 이름들: _UpcomingTile, _RoutineCard,
    // _CalendarRoutineCard, _ProgressRoutineRow
    const retired = [
      '_UpcomingTile',
      '_RoutineCard',
      '_CalendarRoutineCard',
      '_ProgressRoutineRow',
      '_DayTimeline',
    ];
    final sources = [
      'lib/screens/home_screen.dart',
      'lib/screens/routines_screen.dart',
      'lib/screens/today_progress_screen.dart',
    ];
    for (final path in sources) {
      final code = _read(path);
      for (final name in retired) {
        expect(code, isNot(contains('class $name')), reason: '$path의 $name');
      }
    }
  });
}

String _read(String path) => File(path).readAsStringSync();
