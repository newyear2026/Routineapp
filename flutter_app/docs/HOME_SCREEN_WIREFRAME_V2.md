# Home Screen Wireframe V2

이 문서는 `lib/screens/home_screen.dart` 기준으로 홈 화면의 리디자인 구조를 정의한다.

디자인 방향은 `Calm Editorial + Orbit` 이며, 목표는 아래 3가지다.

- 지금 무엇을 해야 하는지 2초 안에 읽힌다.
- 원형 시간표가 통계가 아니라 브랜드 오브제로 보인다.
- 행동 CTA와 상태 정보의 위계가 명확하다.

## 1. 구조 요약

현재 홈은 카드가 순차적으로 쌓이는 구조다.  
V2에서는 `Hero 중심 구조`로 재정렬한다.

```text
Scaffold
└─ HomeDecorativeBackground
└─ SafeArea
   └─ Center
      └─ ConstrainedBox(maxWidth: AppLayout.maxContentWidth)
         └─ Column
            ├─ HomeHeaderBar
            ├─ HomeHeroOrbitSection
            ├─ HomeCurrentRoutineSummary
            ├─ HomePrimaryActionsRow
            ├─ HomeContextCards
            └─ HomeCharacterSection
```

## 2. 섹션별 와이어프레임

### 2.1 Header

역할:

- 날짜
- 짧은 헤드라인
- 오늘 상태 한 줄

```text
+--------------------------------------------------+
| 4월 20일 일요일                                  |
| 오늘의 궤도                                      |
| 집중 블록 종료까지 20분                          |
+--------------------------------------------------+
```

추천 위젯:

- `HomeHeaderBar`
- 신규 `HomeHeroHeaderCopy`

규칙:

- 날짜는 작고 정제된 라벨 톤
- 메인 헤드라인은 1줄
- 상태는 감성 문구보다 기능 문구 우선

### 2.2 Hero Orbit Section

역할:

- 홈의 주인공
- 현재 시각, 현재 블록, 다음 전환 지점 전달

```text
+--------------------------------------------------+
| TODAY ORBIT                                      |
| 업무에 집중하는 시간                              |
| 원형 시간표로 현재 블록과 다음 전환을 확인       |
|                                                  |
|                 [ ORBIT RING ]                   |
|                    16:10                         |
|                     NOW                          |
|                 [ 업무 블록 ]                    |
|                                                  |
| [현재 블록] [시간대] [지금 상태] [다음 전환]      |
+--------------------------------------------------+
```

추천 위젯:

- `HomeTimelineSection`
- `CircularTimetableArea`
- 신규 `HomeOrbitMetaPills`

규칙:

- 원형 시간표는 가로폭의 핵심 비중을 차지한다.
- 중앙에는 시간과 현재 블록만 둔다.
- 보조 정보는 차트 밖 pill로 정리한다.

### 2.3 Current Routine Summary

역할:

- 행동 전 정보 확인
- 현재 블록의 시작/종료/다음 루틴을 더 명확히 전달

```text
+--------------------------------------------------+
| 현재 루틴                                        |
| 업무                                             |
| 09:00 - 18:00                                    |
| 다음: 운동 · 18:00                               |
+--------------------------------------------------+
```

추천 위젯:

- 기존 `CurrentRoutineCard`
- 또는 `HomeCurrentRoutineSummary` 로 경량화

규칙:

- Hero와 내용이 겹치지 않게, 실행 직전 정보만 남긴다.
- 캐릭터성보다 명확한 시간 정보 우선

### 2.4 Primary Actions Row

역할:

- 완료
- 나중에
- 건너뛰기

```text
+--------------------------------------------------+
| [ 완료하기 ]   [ 나중에 ]   [ 건너뛰기 ]          |
+--------------------------------------------------+
```

추천 위젯:

- `HomeBottomActions`

규칙:

- Primary CTA는 1개만 강하게
- 나머지는 secondary 또는 ghost 성격
- 비활성 상태면 이유 문구를 가까이에 둔다

### 2.5 Context Cards

역할:

- 다음 루틴
- 오늘 진행률
- 보조 인사이트

```text
+----------------------+  +-----------------------+
| 오늘 진행률          |  | 다음 루틴            |
| 3 / 5 완료           |  | 운동 · 18:00         |
+----------------------+  +-----------------------+
```

추천 위젯:

- 기존 `home_now_focus_banner.dart`
- 기존 `current_routine_card.dart`
- 신규 `HomeProgressMiniCard`

규칙:

- 메인 흐름을 방해하지 않는 보조 정보만 배치
- 카드 수는 2개 이내 유지

### 2.6 Character Section

역할:

- 정서적 완충
- 앱의 개성 유지

```text
+--------------------------------------------------+
| 🐻 오늘도 리듬을 잘 만들고 있어요                |
+--------------------------------------------------+
```

추천 위젯:

- `HomeCharacterSection`

규칙:

- 가장 아래에 둔다
- 핵심 정보보다 먼저 읽히면 안 된다

## 3. Flutter 기준 권장 위젯 트리

```text
HomeScreen
└─ AppShell
   └─ SingleChildScrollView
      └─ Column
         ├─ HomeHeaderBar
         ├─ HomeHeroHeaderCopy
         ├─ HomeTimelineSection
         ├─ CurrentRoutineCard or HomeCurrentRoutineSummary
         ├─ HomeBottomActions
         ├─ HomeProgressMiniRow
         └─ HomeCharacterSection
```

## 4. 현재 코드와 매핑

기준 파일:

- `lib/screens/home_screen.dart`
- `lib/widgets/home/home_header_bar.dart`
- `lib/widgets/home/home_timeline_section.dart`
- `lib/widgets/home/circular_timetable_area.dart`
- `lib/widgets/home/current_routine_card.dart`
- `lib/widgets/home/home_bottom_actions.dart`
- `lib/widgets/home/home_character_section.dart`

추천 변경 순서:

1. `HomeTimelineSection` 을 홈의 확실한 hero 로 유지
2. `CurrentRoutineCard` 를 요약 카드 버전으로 축소
3. `HomeBottomActions` 의 버튼 위계를 더 명확히 조정
4. 진행률/다음 루틴 카드 1~2개를 보조 섹션으로 정리
5. 헤더 카피와 캐릭터 섹션의 문구 톤을 통일

## 5. 콘텐츠 우선순위

항상 위에서 아래 순서로 읽혀야 한다.

1. 현재 시간과 현재 블록
2. 즉시 행동
3. 다음 전환
4. 오늘 전체 흐름
5. 감성 요소

## 6. 피해야 할 것

- 카드마다 시각 강조도가 비슷한 구조
- 원형 시간표와 현재 루틴 카드가 같은 정보를 반복하는 배치
- 설명 문장이 길어져 행동 버튼보다 먼저 읽히는 상태
- 캐릭터/장식 요소가 핵심 정보보다 먼저 보이는 구조
