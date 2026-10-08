// Render the production Flutter previews of the two selected widget designs.
import 'dart:io';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/application/home/home_snapshot_builder.dart';
import 'package:routine_timer/widget_medium/home_medium_widget.dart';
import 'package:routine_timer/widget_medium/home_medium_widget_selector.dart';
import 'package:routine_timer/theme/app_theme.dart';
import '../test/support/localization.dart';
import '../test/support/test_doubles.dart';

void main() {
  testWidgets('selected card and ring at normal and minimum widths',
      (tester) async {
    await initializeDateFormatting();
    await (FontLoader('PreviewKorean')
          ..addFont(Future.value(ByteData.sublistView(
              File('/System/Library/Fonts/AppleSDGothicNeo.ttc')
                  .readAsBytesSync()))))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    await (FontLoader('PixelifySans')
          ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf')))
        .load();
    final routines = <Routine>[
      dailyRoutine(id: 'reading', title: '독서', startHour: 21, endHour: 22)
          .copyWith(
              startMinutesFromMidnight: 1260, endMinutesFromMidnight: 1290),
      dailyRoutine(id: 'stretch', title: '스트레칭', startHour: 21, endHour: 22)
          .copyWith(
              startMinutesFromMidnight: 1290, endMinutesFromMidnight: 1320),
      dailyRoutine(id: 'sleep', title: '취침', startHour: 22, endHour: 23)
          .copyWith(
              startMinutesFromMidnight: 1320, endMinutesFromMidnight: 1380),
    ];
    final vm = HomeMediumWidgetSelector.fromSnapshot(
        HomeSnapshotBuilder.build(
            l10n: testL10n,
            nowLocal: DateTime(2026, 10, 7, 21, 18),
            allRoutines: routines,
            logsToday: []),
        testL10n);
    for (final style in HomeWidgetStyle.values) {
      for (final width in [360.0, 250.0]) {
        tester.view
          ..physicalSize = Size(width, 180)
          ..devicePixelRatio = 1;
        final key = GlobalKey();
        await tester.pumpWidget(localizedApp(
            theme: buildRoutineTheme(fontFamily: 'PreviewKorean'),
            home: Material(
                child: RepaintBoundary(
                    key: key,
                    child: HomeMediumWidget(
                        viewModel: vm, style: style, onComplete: () {})))));
        await tester.runAsync(() async {
          await precacheImage(
              const AssetImage(
                  'assets/characters/cat_starlight/v1/approved/idle.png'),
              key.currentContext!);
          await precacheImage(
              const AssetImage('assets/decorations/home-sky.png'),
              key.currentContext!);
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final bytes = await tester.runAsync(() async {
          final image = await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 3);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          return data!.buffer.asUint8List();
        });
        final out = File(
            'output/widget-design-2026-10-07/${style.name}-${width.toInt()}.png');
        out.parent.createSync(recursive: true);
        out.writeAsBytesSync(bytes!);
      }
    }
    tester.view.reset();
  });
}
