import 'time_minutes.dart';

/// 로컬 [DateTime]의 시·분을 하루 기준 분(0~1439)으로 변환 — 문자열 비교 없이 스케줄 계산에 사용
int timeToMinutes(DateTime local) => TimeMinutes.fromDateTime(local);
