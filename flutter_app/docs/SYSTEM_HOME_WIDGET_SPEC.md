# 시스템 홈 위젯 공통 스펙 (Medium)

Flutter는 `home_widget`으로 JSON을 저장하고 iOS WidgetKit·Android App Widget은
같은 페이로드를 읽는다. 저장 키는 `routine_widget_payload`, iOS App Group은
`group.com.dayround.app`, WidgetKit kind는 `RoutineMediumWidget`이다.

## JSON 스키마 v3

`SystemHomeWidgetPayload`가 직렬화의 단일 기준이다. 루트에는 현재 화면 상태,
`characterPackId`, `nextLabel`, `refreshHint`, `validUntilEpochMs`, 다국어 남은 시간 템플릿과
`timelineStates[]`가 있다. 각 타임라인 상태는 다음 필드를 포함한다.

| 필드 | 뜻 |
|---|---|
| `effectiveAtEpochMs` | 이 상태가 시작되는 로컬 루틴 경계의 epoch ms |
| `currentRoutineTitle`, `currentRoutineStatus`, `currentRoutineTimingHint` | 현재 루틴 표시 |
| `nextRoutineTitle`, `nextRoutineTime` | 표시 루틴 다음 일정, 없으면 번역된 `widgetNone` |
| `timingTargetEpochMs`, `timingMode` | 시작·종료까지 남은 시간 재계산용 |
| `ringSegments`, `activeSegmentId` | 해당 날짜의 24시간 링 |

앱은 현재 시점부터 7일 동안의 자정·루틴 시작·종료 경계를 미리 계산한다.
현재 시점과 이후 경계마다 `HomeSnapshotBuilder`와 `HomeMediumWidgetSelector`를
사용하므로, 앱 화면과 동일한 우선순위·상태 판정을 따른다. 오늘 로그는 오늘
상태에만 적용하고 다음 날부터는 빈 로그로 계산한다. 사용자가 루틴이나 상태를
바꾸면 앱이 새 페이로드를 저장하고 위젯을 즉시 갱신한다. 캐릭터 팩을
바꾸면 `characterPackId`에 따라 별빛 고양이(크림·라벤더) 또는 푸들 정원
(라벤더·민트)의 캐릭터 그림, 장식, 배경, 상태 배지가 함께 바뀐다.

## 앱이 꺼졌을 때

- iOS는 WidgetKit 타임라인에 앞으로 24시간 동안 5분 간격과 루틴 경계를
  넣는다. 다음 타임라인 요청에서는 저장된 7일 상태를 다시 읽는다.
- Android는 `AlarmManager`로 다음 5분 경계와 루틴 경계 중 이른 시점에
  갱신을 예약한다. 루틴 경계는 정확 알람 권한이 있으면 정확하게 예약하고,
  5분 시각 갱신은 운영체제가 묶어 처리할 수 있다. 권한이 없으면 루틴
  경계도 부정확 알람으로 후퇴한다.
  중앙 시각은 `TextClock`이 시스템 시간을 직접 표시한다.
- 7일이 지나면 오래된 루틴을 현재 정보처럼 표시하지 않고 앱을 열어
  위젯을 갱신하라는 문구를 표시한다.

운영체제는 배터리 정책에 따라 예약 갱신을 늦출 수 있다. Android 중앙 시각은
그와 무관하게 갱신되지만, 링 포인터·루틴·남은 시간과 iOS 전체 위젯은 다음
허용된 갱신 시점에 반영된다.

스키마 v2에는 미래 상태가 없으므로 네이티브 디코더는 루트 필드를 읽는
호환 경로를 유지한다. 앱을 한 번 열면 v3 페이로드로 바뀐다.
