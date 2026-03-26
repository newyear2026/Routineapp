import 'package:flutter/material.dart';

/// Medium 위젯 원형 링의 한 호(arc) — **동심원 도넛**으로 그릴 때 사용.
///
/// - [startMinutesFromMidnight]: 구간 시작 (0 … 1439, 자정 기준)
/// - [sweepMinutes]: 호의 길이(분). 다음 루틴 시작까지의 분 수(원 위에서 한 바퀴를 넘지 않음)
/// - [color]: 파스텔 링 색
class MediumRingSegment {
  const MediumRingSegment({
    required this.id,
    required this.startMinutesFromMidnight,
    required this.sweepMinutes,
    required this.color,
  });

  final String id;
  final int startMinutesFromMidnight;
  final int sweepMinutes;
  final Color color;
}
