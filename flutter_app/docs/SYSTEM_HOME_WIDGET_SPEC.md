# 시스템 홈 위젯 공통 스펙 (Medium 1종)

## 목적

iOS(WidgetKit)·Android(App Widget) **시스템 위젯**이 동일한 데이터를 표시하기 위한 계약이다.  
Flutter는 `home_widget`으로 JSON 한 덩어리를 저장하고, 네이티브는 이를 파싱한다.

## 식별자

| 항목 | 값 |
|------|-----|
| App Group (iOS) | `group.com.example.routineTimer` |
| SharedPreferences 키 (Android, `home_widget`) | `routine_widget_payload` (전체 JSON 문자열) |
| Dart 저장 키 | 동일 `routine_widget_payload` |

## 정보 우선순위 (표시)

1. 현재 루틴 (제목, 시간대, 상태 배지)  
2. 현재 시각 (중앙/강조)  
3. 다음 루틴 한 줄  
4. 미니 원형 시간표(동심원 도넛) + 포인터  

헤더에 얼굴/캐릭터 아이콘 없음.

## JSON 스키마 `v1`

`schemaVersion`이 `1`이다.

필드:

| 필드 | 타입 | 설명 |
|------|------|------|
| schemaVersion | int | 항상 1 |
| headerTitle | string | 예: 하루 루틴 시간표 |
| subtitle | string | 예: 오늘 루틴 진행 중 |
| currentRoutineTitle | string | |
| currentRoutineIconEmoji | string | |
| currentRoutineTimeRange | string | `HH:mm - HH:mm` |
| currentRoutineStatus | string | 배지 텍스트 |
| nextRoutineLine | string | 한 줄 요약 |
| nextRoutineTitle | string | 파싱·접근성용 |
| nextRoutineTime | string | `HH:mm` |
| currentTimeHour | int | 0–23 |
| currentTimeMinute | int | 0–59 |
| pointerAngleRad | double | 24h 시계, 0시=위, 라디안 |
| centerTimeLabel | string | 예: 현재 시간 |
| ringSegments | array | 아래 참조 |
| activeSegmentId | string? | 활성 구간 id |

`ringSegments[]`:

| 필드 | 타입 |
|------|------|
| id | string |
| startMinutesFromMidnight | int |
| sweepMinutes | int |
| colorArgb | int | Flutter `Color.value` (0xAARRGGBB) |

## 네이티브 구현 메모

- **iOS**: `UserDefaults(suiteName: App Group)`에서 `routine_widget_payload` 문자열 읽기 → `WidgetKit` 타임라인 갱신은 Flutter `HomeWidget.updateWidget(iOSName:)` 호출 시.  
- **Android**: `HomeWidgetPreferences` SharedPreferences, 동일 키. Provider는 `es.antonborri.home_widget.HomeWidgetProvider` 상속.  
- 색상은 `colorArgb` 정수로 통일해 Kotlin/Swift에서 동일하게 해석한다.
