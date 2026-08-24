import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/data/seed/routine_seed.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/onboarding/recommended_routine_catalog.dart';
import 'support/localization.dart';

/// 루틴의 정체성은 **색상**으로 표현한다.
///
/// 예전에는 온보딩 루틴은 빈 값, 직접 추가한 루틴은 `Routine.create`의
/// 기본값 `📌`가 붙어, 같은 목록에서 어떤 줄에는 압정이 있고 어떤 줄에는
/// 없었다. 정책은 카탈로그에만 반영되고 생성 경로에는 빠져 있었다.
void main() {
  test('직접 추가한 루틴에는 이모지가 붙지 않는다', () {
    final routine = Routine.create(
      title: '아침 산책',
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 10, minute: 0),
      repeatWeekdays: const {1},
      colorValue: 0xFF6C4CF1,
    );

    expect(routine.iconEmoji, isEmpty);
  });

  test('추천 루틴과 시드 루틴도 이모지를 갖지 않는다', () {
    for (final def in RecommendedRoutineCatalog.items) {
      expect(def.toRoutine('x').iconEmoji, isEmpty, reason: def.catalogId);
    }
    for (final routine in RoutineSeed.defaultRoutines(testL10n)) {
      expect(routine.iconEmoji, isEmpty, reason: routine.title);
    }
  });

  test('화면 코드가 iconEmoji를 다시 그리지 않는다', () {
    // 필드는 저장 호환과 향후 이모지 선택 UI를 위해 남겨두지만,
    // 지금은 어떤 화면도 이것을 렌더링하지 않는다.
    final offenders = <String>[];
    for (final dir in ['lib/screens', 'lib/widgets', 'lib/widget_medium']) {
      for (final entity in Directory(dir).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        // 주석의 설명은 세지 않는다 — 실제로 값을 읽는 코드만 본다.
        final code = entity
            .readAsLinesSync()
            .where((line) => !line.trimLeft().startsWith('//'))
            .join('\n');
        if (code.contains('iconEmoji') || code.contains('IconEmoji')) {
          offenders.add(entity.path);
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: '이모지를 다시 표시하려면 선택 UI부터 만든다: $offenders',
    );
  });
}
