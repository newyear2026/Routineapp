import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/domain/utils/time_minutes.dart';

void main() {
  group('TimeMinutes', () {
    test('formatHm은 두 자리로 맞춘다', () {
      expect(TimeMinutes.formatHm(0), '00:00');
      expect(TimeMinutes.formatHm(7 * 60 + 5), '07:05');
      expect(TimeMinutes.formatHm(23 * 60 + 59), '23:59');
    });

    test('formatRange는 공백 없는 en dash로 잇는다', () {
      expect(TimeMinutes.formatRange(7 * 60, 8 * 60), '07:00–08:00');
    });

    test('formatTimeOfDay', () {
      expect(
        TimeMinutes.formatTimeOfDay(const TimeOfDay(hour: 9, minute: 3)),
        '09:03',
      );
    });
  });

  test('시각 포맷 구현은 TimeMinutes 하나뿐이다', () {
    // 예전에는 화면·페이로드가 각자 _time()/_hm()을 들고 있어 5벌이 돌아다녔다.
    // 포맷을 바꾸면 어딘가 하나가 옛 모양으로 남는다.
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('domain/utils/time_minutes.dart')) continue;
      if (entity.readAsStringSync().contains("padLeft(2, '0')")) {
        offenders.add(entity.path);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: '시각을 직접 만들지 말고 TimeMinutes를 쓴다: $offenders',
    );
  });
}
