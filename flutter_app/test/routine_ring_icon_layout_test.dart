import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/domain/models/routine_icon_id.dart';
import 'package:routine_timer/models/home_models.dart';
import 'package:routine_timer/widgets/home/routine_ring_icon_layout.dart';

RoutineSegment segment(String id, int start, int end) => RoutineSegment(
      id: id,
      startMinutesFromMidnight: start,
      endMinutesFromMidnight: end,
      label: id,
      emoji: '',
      color: Colors.purple,
      iconId: RoutineIconId.book,
    );

void main() {
  test('아이콘은 구간의 중간 각도에 배치된다', () {
    final placements = RoutineRingIconLayout.arrange(
      segments: [segment('morning', 6 * 60, 7 * 60)],
      dialSize: 280,
      activeSegmentId: '',
    );

    expect(placements, hasLength(1));
    expect(placements.single.center.dx, greaterThan(140));
    expect(placements.single.center.dy, greaterThan(140));
  });

  test('좁은 구간과 겹치는 배지는 숨기고 현재 루틴을 우선한다', () {
    final placements = RoutineRingIconLayout.arrange(
      segments: [
        segment('short', 9 * 60, 9 * 60 + 10),
        segment('earlier', 9 * 60, 10 * 60),
        segment('active', 9 * 60 + 30, 10 * 60 + 30),
        segment('later', 11 * 60, 12 * 60),
      ],
      dialSize: 280,
      activeSegmentId: 'active',
    );

    final ids = placements.map((p) => p.segment.id).toSet();
    expect(ids, contains('active'));
    expect(ids, contains('later'));
    expect(ids, isNot(contains('short')));
    expect(ids, isNot(contains('earlier')));
    for (var i = 0; i < placements.length; i++) {
      for (var j = i + 1; j < placements.length; j++) {
        expect(
          placements[i].bounds.inflate(3).overlaps(placements[j].bounds),
          isFalse,
        );
      }
    }
  });
}
