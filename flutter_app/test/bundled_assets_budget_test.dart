import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// 번들 그림은 화면에서 쓰는 크기로만 싣는다.
///
/// 고양이·장식 PNG를 1254px 원본 그대로 올려 4.9MB를 앱에 싣고 있었다.
/// 화면에서 가장 큰 자리는 알림 권한 화면의 종 108이고, 코드도
/// `cacheWidth` 384/256으로 디코딩하므로 3x 기기까지 384면 충분하다.
/// 원본은 `design/decorations-src`와 `assets/characters/.../v1`에 남겨 둔다.
void main() {
  const maxEdge = 384;
  const maxBytes = 130 * 1024;
  const bundledDirs = [
    'assets/decorations',
    'assets/characters/cat_starlight/v1/approved',
    'assets/characters/poodle_garden/v1/approved',
    'assets/routine_icons',
  ];

  List<File> bundledPngs() => [
        for (final dir in bundledDirs)
          ...Directory(dir)
              .listSync()
              .whereType<File>()
              .where((file) => file.path.endsWith('.png')),
      ]..sort((a, b) => a.path.compareTo(b.path));

  test('번들 그림과 루틴 아이콘은 384px·130KB를 넘지 않는다', () {
    final files = bundledPngs();
    expect(files, isNotEmpty);

    for (final file in files) {
      final bytes = file.readAsBytesSync();
      // PNG IHDR: 시그니처 8 + 길이 4 + 'IHDR' 4 다음이 폭·높이다.
      final header = ByteData.sublistView(bytes);
      final width = header.getUint32(16);
      final height = header.getUint32(20);

      expect(width, lessThanOrEqualTo(maxEdge),
          reason: '${file.path} 폭 $width');
      expect(height, lessThanOrEqualTo(maxEdge),
          reason: '${file.path} 높이 $height');
      expect(bytes.length, lessThanOrEqualTo(maxBytes),
          reason: '${file.path} ${(bytes.length / 1024).round()}KB');
    }
  });

  test('pubspec은 번들 그림을 하나도 빠뜨리지 않고 문서는 싣지 않는다', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    // 디렉터리째 올리면 옆에 둔 README·ANIMATION·manifest까지 앱에 실린다.
    for (final dir in bundledDirs) {
      expect(pubspec, isNot(contains('- $dir/\n')),
          reason: '$dir 를 디렉터리째 올리면 문서 파일까지 번들된다');
    }
    // 대신 파일을 하나씩 적으므로, 새 그림을 추가하고 등록을 잊으면
    // 런타임에야 깨진다. 여기서 먼저 잡는다.
    for (final file in bundledPngs()) {
      expect(pubspec, contains('- ${file.path}\n'),
          reason: '${file.path} 가 pubspec assets에 없다');
    }
  });
}
