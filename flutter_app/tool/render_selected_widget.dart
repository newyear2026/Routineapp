// flutter test tool/render_selected_widget.dart \
//   --dart-define=PREVIEW_FONT=/System/Library/Fonts/AppleSDGothicNeo.ttc
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/theme/app_theme.dart';
import 'package:routine_timer/widget_medium/home_medium_widget.dart';
import 'package:routine_timer/widget_medium/home_medium_widget_view_model.dart';
import 'package:routine_timer/widget_medium/medium_ring_segment.dart';

import '../test/support/localization.dart';

void main() {
  testWidgets('선택한 Medium 위젯 시안 렌더', (tester) async {
    const fontPath = String.fromEnvironment('PREVIEW_FONT');
    if (fontPath.isEmpty) throw StateError('PREVIEW_FONT이 필요합니다.');
    await (FontLoader('PreviewKorean')
          ..addFont(Future.value(
              ByteData.sublistView(File(fontPath).readAsBytesSync()))))
        .load();
    await (FontLoader('PixelifySans')
          ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf')))
        .load();

    tester.view
      ..physicalSize = const Size(760, 440)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    const vm = HomeMediumWidgetViewModel(
      currentRoutineTitle: '저녁식사',
      currentRoutineTimingHint: '종료까지 58분 남음',
      currentRoutineStatusLabel: '진행 중',
      nextRoutineTitle: '취침',
      nextRoutineTime: '23:00',
      currentTime: TimeOfDay(hour: 18, minute: 2),
      centerTimeLabel: '지금',
      activeSegmentId: 'dinner',
      ringSegments: [
        MediumRingSegment(
            id: 'focus',
            startMinutesFromMidnight: 0,
            sweepMinutes: 40,
            color: Color(0xFF6744F4)),
        MediumRingSegment(
            id: 'rest',
            startMinutesFromMidnight: 13 * 60,
            sweepMinutes: 30,
            color: Color(0xFF57C589)),
        MediumRingSegment(
            id: 'dinner',
            startMinutesFromMidnight: 18 * 60,
            sweepMinutes: 60,
            color: Color(0xFF6744F4)),
        MediumRingSegment(
            id: 'sleep',
            startMinutesFromMidnight: 21 * 60,
            sweepMinutes: 40,
            color: Color(0xFFFF6B84)),
        MediumRingSegment(
            id: 'prepare',
            startMinutesFromMidnight: 22 * 60,
            sweepMinutes: 30,
            color: Color(0xFFFFB641)),
      ],
    );
    await tester.pumpWidget(localizedApp(
      theme: buildRoutineTheme(fontFamily: 'PreviewKorean'),
      home: Scaffold(
        backgroundColor: const Color(0xFFE9E4F7),
        body: RepaintBoundary(
          key: key,
          child: const ColoredBox(
            color: Color(0xFFE9E4F7),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 330, child: HomeMediumWidget(viewModel: vm)),
                  SizedBox(height: 30),
                  SizedBox(width: 250, child: HomeMediumWidget(viewModel: vm)),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    final file = File('output/widget-redesign-2026-09-26/preview.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!);
  });
}
