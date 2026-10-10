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
| `currentRoutineTimeRange` | 표시 루틴의 시간대(예: `18:00–19:00`), 4×2 링이 쓴다 |
| `upcomingRoutines[]` | 표시 루틴 뒤 오늘 남은 루틴 최대 3개(`title`, `time`, `colorArgb`), 기존 클라이언트 호환용 데이터 |
| `timelineItems[]` | 가로 시간선에 표시할 현재/예정 루틴과 다음 두 일정. `id`, `title`, `time`, `startEpochMs`를 담으며 없으면 빈 배열 |

루트에는 같은 두 필드와 4×2 링 가운데 문구 `ringUntilStartLabel`·`ringUntilEndLabel`,
기존 목록 머리말 `upNextLabel`도 있다. 모두 옵셔널이라 스키마 번호는 v3 그대로다.

앱은 현재 시점부터 7일 동안의 자정·루틴 시작·종료 경계를 미리 계산한다.
현재 시점과 이후 경계마다 `HomeSnapshotBuilder`와 `HomeMediumWidgetSelector`를
사용하므로, 앱 화면과 동일한 우선순위·상태 판정을 따른다. 오늘 로그는 오늘
상태에만 적용하고 다음 날부터는 빈 로그로 계산한다. 사용자가 루틴이나 상태를
바꾸면 앱이 새 페이로드를 저장하고 위젯을 즉시 갱신한다. 캐릭터 팩을
바꾸면 `characterPackId`에 따라 별빛 고양이(크림·라벤더) 또는 푸들 정원
(라벤더·민트)의 캐릭터 그림, 장식, 배경, 상태 배지가 함께 바뀐다.

Android 런처에는 위젯 세 가지가 별도 항목으로 나타난다. 원형 시간표(Circle, 기본 4×2),
가로 시간선(Timeline, 기본 4×2), 현재·다음 루틴 카드형(Cards, 기본 4×2)이다. 모두 같은 JSON 페이로드를
읽고 캐릭터 팩에 맞춰 배경·캐릭터·배지 색을 바꾼다. Flutter가 데이터를
저장하면 세 제공자를 모두 갱신하며, 각 제공자는 앱이 닫혀 있을 때도
자신의 알람으로 다음 루틴 경계와 5분 경계에서 다시 그린다.

기존 한 줄 시간선과 카드형은 768×240 비트맵에 픽셀 아트 배경·루틴 데이터·캐릭터를
합성한다. 새 4×2 위젯은 아래의 네이티브 텍스트·버튼 레이아웃을 사용한다. 한 줄 위젯의 시각은
`TextClock`이 분 단위로 표시한다. 런처 선택 화면의 세 가지 미리보기는 실제 Android
RemoteViews 렌더링을 사용한다.

세 위젯은 세로로 늘이고 줄일 수 있다. 위젯 높이(`OPTION_APPWIDGET_MAX_HEIGHT`)가
140dp 이상이면 완료 버튼이 있는 새 레이아웃을, 그보다 낮으면 기존 한 줄 레이아웃을 그린다. 크기를
바꾸면 `onAppWidgetOptionsChanged`에서 바로 다시 고른다. 이미 한 줄로 놓인 위젯은
런처가 배치를 유지하므로, 사용자가 크기 조절 손잡이로 늘리거나 새로 추가해야 4×2가 된다.

## 앱이 꺼졌을 때

- iOS는 WidgetKit 타임라인에 앞으로 24시간 동안 5분 간격과 루틴 경계를
  넣는다. 다음 타임라인 요청에서는 저장된 7일 상태를 다시 읽는다.
- Android는 위젯별 `AlarmManager`로 다음 5분 경계와 루틴 경계 중 이른 시점에
  갱신을 예약한다. 루틴 경계는 정확 알람 권한이 있으면 정확하게 예약하고,
  5분 시각 갱신은 운영체제가 묶어 처리할 수 있다. 권한이 없으면 루틴
  경계도 부정확 알람으로 후퇴한다.
  한 줄 위젯의 시각은 `TextClock`이 시스템 시간을 직접 표시한다.
  새 원형 위젯의 중앙 남은 시간 또는 시각은 위젯 갱신 시점에 함께 바뀐다.
- 7일이 지나면 오래된 루틴을 현재 정보처럼 표시하지 않고 앱을 열어
  위젯을 갱신하라는 문구를 표시한다.

운영체제는 배터리 정책에 따라 예약 갱신을 늦출 수 있다. Android 한 줄 위젯 시각은
그와 무관하게 갱신되지만, 새 원형의 중앙 표시·링 포인터·루틴·남은 시간과 iOS 전체 위젯은 다음
허용된 갱신 시점에 반영된다.

스키마 v2에는 미래 상태가 없으므로 네이티브 디코더는 루트 필드를 읽는
호환 경로를 유지한다. 앱을 한 번 열면 v3 페이로드로 바뀐다.


## Android 카드·원형 위젯 개선 (2026-10-07)

선택된 이미지 시안 1은 `RoutineCardsWidgetProvider`, 시안 2는
`RoutineMediumWidgetProvider`의 기본 4×2 레이아웃에 적용했다. iOS WidgetKit의
레이아웃과 인터랙션은 이번 변경 범위에 포함하지 않는다.

- 카드형: 현재 상태·시간대·루틴명·남은 시간을 왼쪽, 캐릭터를 오른쪽,
  다음 일정과 완료 버튼을 아래에 배치한다.
- 원형: 루틴명·시간대·완료 버튼·다음 일정을 왼쪽, 남은 시간이 있는
  24시간 원판과 캐릭터를 오른쪽에 배치한다.
- 두 형태 모두 네이티브 TextView와 실제 PendingIntent 버튼을 사용한다.
  300dp 미만의 폭 또는 180dp 미만 높이는 작은 전용 레이아웃을 고른다.
- 새 배치는 기본 높이 180dp, 최소 조절 높이 160dp다. 이미 놓인 한 줄
  위젯은 런처가 이전 크기를 유지할 수 있으므로 늘리거나 다시 추가한다.
- 미리보기 화면은 카드·원형 두 디자인을 보여준다. 예시 데이터에서 완료를
  누르면 예시만 바뀌며, 실제 데이터에서 누르면 앱의 완료 처리를 사용한다.

JSON v3의 루트와 각 타임라인 상태에 선택 필드 `completeActionUri`,
`completeLabel`을 추가했다. 액션은 루틴 ID, 실행 날짜(취침은 기상일),
루틴 버전과 시작·종료 시각을 담는다. 다가오는 루틴·완료·스킵·만료된
페이로드에는 실행 가능한 버튼을 표시하지 않는다.

Android는 `HomeWidgetBackgroundReceiver`의 명시적 PendingIntent로
`routineWidgetBackgroundAction`을 호출한다. `WidgetCompletionService`가
저장된 정의와 기록을 새로 읽어 날짜·버전·액션 가능 여부를 확인한 뒤
Repository를 통해 기록한다. Android의 공유 저장 잠금 안에서 중복 완료와
스킵 덮어쓰기를 막고, 앱에 기록 변경을 알린다. 쓰기 후 스누즈 알람을
취소하고 세 위젯의 7일 페이로드를 다시 생성한다. 저장 실패를 완료로
표시하지 않는다. 전체 위젯 영역을 누르면 앱을 연다.

검증: `test/widget_completion_service_test.dart`에서 날짜·버전·중복·겹침·취침을
검사한다. `tool/render_widget_redesign.dart`는 실제 Flutter 미리보기를 렌더링한다.
`WidgetRenderInstrumentation`은 저장된 루틴/로그를 건드리지 않고 실제 Android
RemoteViews의 카드·원형·좁은 폭·완료 상태를 렌더링하고 버튼 바인딩을 확인한다.

## Android 가로 시간선 개선 (2026-10-08)

추가로 선택한 이미지 시안은 기존 `RoutineTimelineWidgetProvider`에 적용했다.
왼쪽 캐릭터, 가운데 상태·루틴명·남은 시간, 오른쪽 완료 버튼 아래에 최대 세 일정을 배치한다.
앱 위젯 미리보기에서도 카드·원형에 이어 세 번째 디자인으로 표시한다.

`timelineItems`는 공통 selector가 표시 루틴과 이후 일정 두 개로 만든다. 루트와
각 미래 경계 상태에 동일하게 저장하며, 날짜가 있는 시작 epoch를 사용해 자정을 넘기는
취침도 올바르게 표시한다. 현재 시각과 인접 두 일정의 시작 시각으로 진행선 길이를
계산한다. 일정이 한 개면 점 하나만, 두 개면 두 점만 표시하고, 빈 일정이나 만료된
페이로드에는 시간선을 숨긴다. 임의의 예정 루틴을 추가하지 않는다.

기본 크기는 4×2 / 180dp이며 250×160dp용 작은 레이아웃도 제공한다. 기존 4×1
배치는 크기를 늘리거나 위젯을 다시 추가하기 전까지 이전 한 줄 디자인을 유지한다.
완료 액션은 카드·원형과 같은 저장·중복 방지·위젯 갱신 경로를 사용한다.

추가 검증은 `test/widget_timeline_design_test.dart`에서 경계 전환·실제 일정 수·취침
날짜·다섯 언어·두 폭의 버튼 동작을 확인한다. 네이티브 렌더링 검사에도 가로 시간선,
빈 일정, 일정 한 개/두 개, 완료, 만료 시 버튼/시간선 숨김 검사를 추가했다.
