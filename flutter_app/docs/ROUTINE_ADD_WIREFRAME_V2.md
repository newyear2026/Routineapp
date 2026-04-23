# Routine Add Screen Wireframe V2

이 문서는 `lib/screens/routine_add_screen.dart` 기준으로 루틴 추가/편집 화면의 리디자인 구조를 정의한다.

핵심 목표는 `입력 폼` 이 아니라 `하루 블록 설계 경험`을 만드는 것이다.

## 1. 구조 요약

현재 화면은 여러 `AppCard` 안에 입력이 분산되어 있다.  
V2에서는 `미리보기 중심 설계 흐름`으로 재정렬한다.

```text
Scaffold
└─ AppPageHeader
└─ SingleChildScrollView
   └─ Column
      ├─ RoutineBuilderHero
      ├─ RoutineIdentitySection
      ├─ RoutineTimeBlockSection
      ├─ RoutineRepeatSection
      ├─ RoutineColorMoodSection
      ├─ RoutineNotificationSection
      ├─ RoutineValidationSummary
      └─ RoutineSaveBar
```

## 2. 섹션별 와이어프레임

### 2.1 Builder Hero

역할:

- 지금 만드는 루틴이 하루 흐름에서 어디에 놓이는지 즉시 보여줌

```text
+--------------------------------------------------+
| 새 루틴 만들기                                   |
| 하루에 자연스럽게 들어갈 블록을 설계해보세요     |
|                                                  |
|                 [ ORBIT PREVIEW ]                |
|                    09:00-10:00                   |
|                 [ 아침 스트레칭 ]                |
|                                                  |
| [이름] [시간] [요일] [색상]                       |
+--------------------------------------------------+
```

추천 위젯:

- 기존 `CircularTimetableArea` 재사용
- 신규 `RoutinePreviewHero`
- 기존 `_FormProgressChip` 재사용 가능

규칙:

- 사용자가 값을 바꿀 때마다 preview가 즉시 반영된다.
- 상단 미리보기만 봐도 결과를 이해할 수 있어야 한다.

### 2.2 Identity Section

역할:

- 루틴 이름
- 짧은 설명 또는 메모

```text
+--------------------------------------------------+
| 기본 정보                                        |
| [ 루틴 이름 입력 ]                               |
| 홈 화면과 알림에 표시될 이름이에요               |
+--------------------------------------------------+
```

추천 위젯:

- `PastelTextField`

규칙:

- 필드 수를 최소화한다.
- 라벨, 입력, 도움말 순서를 유지한다.

### 2.3 Time Block Section

역할:

- 시작/종료 시간
- 시간 블록 의미 전달

```text
+--------------------------------------------------+
| 시간 블록                                        |
| [ 시작 09:00 ]   [ 종료 10:00 ]                  |
| 하루 원형 일정표에서 이 블록의 길이를 정합니다   |
+--------------------------------------------------+
```

추천 위젯:

- `PastelTimeField`
- 신규 `RoutineTimeSummaryPill`

규칙:

- 시간 입력은 항상 쌍으로 읽힌다.
- 시작/종료보다 `블록` 개념이 먼저 느껴져야 한다.

### 2.4 Repeat Section

역할:

- 반복 요일 선택
- 미리보기 기준일 선택 보조

```text
+--------------------------------------------------+
| 반복 요일                                        |
| [월] [화] [수] [목] [금] [토] [일]               |
| 평일 반복 / 주말 반복 / 직접 선택                |
+--------------------------------------------------+
```

추천 위젯:

- `PastelWeekdaySelector`

규칙:

- 선택 결과는 `매일 반복`, `평일 반복` 같은 요약 문구로 함께 보여준다.

### 2.5 Color Mood Section

역할:

- 루틴 색상 선택
- 홈/원형 시간표에서 구분되는 시각 톤 결정

```text
+--------------------------------------------------+
| 이 블록의 톤                                     |
| [ 색상 팔레트 ]                                  |
| 선택한 색은 시간표와 홈 카드에 반영됩니다        |
+--------------------------------------------------+
```

추천 위젯:

- `PastelColorPalette`

규칙:

- 색은 장식이 아니라 구분 수단이다.
- 선택 즉시 preview segment 색이 바뀌어야 한다.

### 2.6 Notification Section

역할:

- 알림 여부 선택

```text
+--------------------------------------------------+
| 알림 받기                                        |
| 루틴 시작 시각에 맞춰 1회 알려드릴게요           |
| [ ON / OFF ]                                     |
+--------------------------------------------------+
```

추천 위젯:

- `PastelSwitchTile`

### 2.7 Validation Summary

역할:

- 저장 직전 현재 입력 상태 확인

```text
+--------------------------------------------------+
| 입력 상태                                        |
| [ 이름 완료 ] [ 시간 완료 ] [ 요일 완료 ]         |
| 겹치는 루틴이 있으면 여기서 먼저 알려줌          |
+--------------------------------------------------+
```

추천 위젯:

- `_FormProgressChip`
- 신규 `RoutineConflictBanner`

규칙:

- 오류는 저장 후가 아니라 저장 전에 읽히게 한다.

### 2.8 Save Bar

역할:

- 저장
- 삭제 또는 취소

```text
+--------------------------------------------------+
| [ 삭제 ]                             [ 저장 ]    |
+--------------------------------------------------+
```

추천 위젯:

- `AppButton`

규칙:

- 저장 버튼은 화면에서 가장 강해야 한다.
- 삭제는 편집 상태에서만 노출한다.

## 3. Flutter 기준 권장 위젯 트리

```text
RoutineAddScreen
└─ AppShell
   └─ Column
      ├─ AppPageHeader
      └─ SingleChildScrollView
         └─ Column
            ├─ RoutinePreviewHero
            ├─ AppCard(Identity)
            ├─ AppCard(Time Block)
            ├─ AppCard(Repeat)
            ├─ AppCard(Color Mood)
            ├─ AppCard(Notification)
            ├─ AppCard(Validation Summary)
            └─ RoutineSaveBar
```

## 4. 현재 코드와 매핑

기준 파일:

- `lib/screens/routine_add_screen.dart`
- `lib/widgets/form/pastel_text_field.dart`
- `lib/widgets/form/pastel_time_field.dart`
- `lib/widgets/form/pastel_weekday_selector.dart`
- `lib/widgets/form/pastel_color_palette.dart`
- `lib/widgets/form/pastel_switch_tile.dart`
- `lib/widgets/home/circular_timetable_area.dart`

추천 변경 순서:

1. 현재 `입력 미리보기` 카드를 상단 `RoutinePreviewHero` 로 승격
2. 카드 순서를 `기본 정보 -> 시간 -> 요일 -> 색상 -> 알림` 에서 `미리보기 -> 이름 -> 시간 -> 요일 -> 색상 -> 알림` 으로 재정렬
3. 겹침 경고를 저장 직전 summary 에 더 명확하게 배치
4. 저장 영역을 하단 sticky bar 성격으로 강화

## 5. 콘텐츠 우선순위

1. 지금 만들고 있는 블록이 어떻게 보이는지
2. 저장에 필요한 최소 입력
3. 반복/색상/알림 같은 보조 설정
4. 저장 가능 여부

## 6. 피해야 할 것

- 미리보기가 화면 아래로 밀려서 입력 결과를 바로 볼 수 없는 구조
- 모든 카드가 동일한 위계로 보여 시선이 분산되는 구조
- 색상 선택이 결과 화면과 연결되지 않는 상태
- 저장 버튼이 스크롤 하단에 묻혀 존재감이 약한 구조
