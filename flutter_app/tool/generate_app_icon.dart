// Approved artwork exports: flutter test tool/generate_app_icon.dart
// Then: dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('export approved cat clock launcher assets', (tester) async {
    await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(
          File('design/app-icon/cat-clock-approved.png').readAsBytesSync());
      final source = (await codec.getNextFrame()).image;
      final pixels =
          (await source.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      final background = ui.Color.fromARGB(
          255, pixels.getUint8(0), pixels.getUint8(1), pixels.getUint8(2));
      for (final spec in [
        ('app_icon.png', 1024, .90),
        ('app_icon_foreground.png', 1024, .72),
        ('play_store_512.png', 512, .90),
      ]) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        final size = spec.$2.toDouble();
        canvas.drawColor(background, ui.BlendMode.src);
        final edge = size * spec.$3;
        canvas.drawImageRect(
            source,
            ui.Rect.fromLTWH(
                0, 0, source.width.toDouble(), source.height.toDouble()),
            ui.Rect.fromLTWH((size - edge) / 2, (size - edge) / 2, edge, edge),
            ui.Paint()..filterQuality = ui.FilterQuality.none);
        final picture = recorder.endRecording();
        final image = await picture.toImage(spec.$2, spec.$2);
        final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        File('assets/icon/${spec.$1}')
            .writeAsBytesSync(data.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      }
      source.dispose();
      codec.dispose();
    });
  });
}
