# Design System V2

이 문서는 `Routine Timer` 앱의 V2 디자인 시스템 초안이다.

방향성은 `Calm Editorial + Orbit` 이다.

- Calm: 과하게 자극적이지 않다.
- Editorial: 정보 위계와 카피 톤이 정제돼 있다.
- Orbit: 시간 흐름을 원형 메타포로 일관되게 사용한다.

관련 기준 파일:

- `lib/theme/app_colors.dart`
- `lib/theme/app_text_styles.dart`
- `lib/theme/app_spacing.dart`
- `lib/theme/design_system.dart`
- `docs/UI_STANDARDS.md`

## 1. Design Principles

### 1.1 Clarity First

- 화면은 2초 안에 핵심 상태를 읽을 수 있어야 한다.
- 한 화면에 주인공은 1개만 둔다.
- 설명보다 상태와 행동이 먼저 읽혀야 한다.

### 1.2 One Strong Object

- 홈에서는 원형 시간표가 주인공이다.
- 폼에서는 미리보기 hero 가 주인공이다.
- 보조 카드가 hero 와 경쟁하면 안 된다.

### 1.3 Calm but Precise

- 부드러운 배경을 사용하되 핵심 정보 대비는 충분히 확보한다.
- 귀엽기보다 정교함을 우선한다.
- 이모지는 의미가 있을 때만 사용한다.

## 2. Color Tokens

### 2.1 Core Surface

| Token | Value | Usage |
|---|---|---|
| `bg/base` | `#EEE8DE` | 앱 기본 배경 |
| `bg/elevated` | `#FFFFFF` | 카드, 패널 |
| `bg/soft` | `#E7E0D4` | 보조 pill, 서브 서피스 |
| `line/subtle` | `#DCD3C4` | 경계선 |
| `line/strong` | `#D9D1F2` | 강조 보더 |

`bg/base`와 `bg/elevated`의 명도차는 ΔL\* ≈ 8을 유지한다.
이보다 좁으면 카드가 배경에 묻혀 그림자로만 구분된다.

### 2.2 Text

| Token | Value | Usage |
|---|---|---|
| `text/primary` | `#241F31` | 핵심 텍스트 |
| `text/secondary` | `#6B6478` | 보조 텍스트 |
| `text/tertiary` | `#958EA3` | 힌트, 약한 라벨 |

### 2.3 Brand

| Token | Value | Usage |
|---|---|---|
| `brand/primary` | `#6C4CF1` | 메인 브랜드 강조 |
| `brand/secondary` | `#E5866B` | 전환, 액션 보조 |
| `brand/accent` | `#F2C14E` | 현재 시점, 하이라이트 |

### 2.4 Semantic

| Token | Value | Usage |
|---|---|---|
| `state/focus` | `#4F46D8` | 집중, 업무 |
| `state/rest` | `#D7C7F4` | 휴식 |
| `state/exercise` | `#F1A089` | 운동 |
| `state/sleep` | `#7C67C8` | 수면 |
| `state/prepare` | `#F2C9A0` | 준비 |

### 2.5 Status Text

상태 색은 **채움용과 글자용을 분리**한다.
`success`(`#7FDD8F`)·`orbitAccent`(`#F2C14E`) 같은 밝은 톤은 흰 서피스 위에서
1.6:1 수준이라 글자에 쓸 수 없다.

| Token | Value | 흰 배경 대비 | Usage |
|---|---|---|---|
| `text/success` | `#2E7D4F` | 5.0:1 | '완료' 라벨·아이콘 |
| `text/scheduled` | `#8A6320` | 5.4:1 | '예정' 라벨·아이콘 |
| `text/active` | `#6C4CF1` | 5.3:1 | '진행 중' 라벨·아이콘 |
| `text/danger` | `#B03A2E` | 4.8:1 | 에러 문구, 삭제 |

## 3. Gradient Tokens

| Token | Value | Usage |
|---|---|---|
| `gradient/pageSoft` | `#EEE8DE -> #F2ECE3 -> #EBE5F0` | 페이지 배경 |
| `gradient/cardSoft` | `#FFFFFF -> #FCFAFF` | 카드 배경 |
| `gradient/orbitPrimary` | `#5E43E8 -> #8E6AF5` | 원형 시간표 active 상태 |
| `gradient/orbitWarm` | `#E5866B -> #F2C14E` | 현재 시점 glow |

## 4. Typography

| Token | Spec | Usage |
|---|---|---|
| `display/lg` | `40 / 800 / tight` | hero 숫자 |
| `display/md` | `32 / 700` | 메인 헤드라인 |
| `title/lg` | `24 / 700` | 카드/섹션 타이틀 |
| `title/md` | `20 / 600` | 보조 타이틀 |
| `body/lg` | `16 / 500` | 본문 |
| `body/md` | `14 / 500` | 보조 본문 |
| `label/lg` | `13 / 700` | strong label |
| `label/sm` | `11 / 700` | meta label |
| `numeric/hero` | `42 / 800 / tabular` | 시각, 큰 수치 |

타이포 규칙:

- 헤드라인은 가능하면 1줄
- 숫자는 정보보다 먼저 읽힌다
- 설명 문구는 짧고 기능 중심
- 감성 카피는 화면당 1개만 허용

## 5. Shape Tokens

| Token | Value | Usage |
|---|---|---|
| `shape/panel` | `28dp` | 메인 패널 |
| `shape/card` | `24dp` | 일반 카드 |
| `shape/pill` | `999dp` | pill, chip |
| `shape/orb` | `circle` | 원형 버튼, 현재 시점 |

## 6. Spacing Tokens

| Token | Value |
|---|---|
| `space/1` | `4dp` |
| `space/2` | `8dp` |
| `space/3` | `12dp` |
| `space/4` | `16dp` |
| `space/5` | `20dp` |
| `space/6` | `24dp` |
| `space/7` | `32dp` |
| `space/8` | `40dp` |

## 7. Elevation and Motion

### 7.1 Elevation

| Token | Value | Usage |
|---|---|---|
| `elevation/0` | `0dp` | 플랫 배경 |
| `elevation/1` | `2dp` | 가벼운 패널 |
| `elevation/2` | `6dp` | 메인 카드 |
| `shadow/soft` | `low blur / low alpha` | 부드러운 깊이 |

### 7.2 Motion

| Token | Value | Usage |
|---|---|---|
| `motion/fast` | `180ms` | 버튼, chip |
| `motion/base` | `280ms` | 섹션 전환 |
| `motion/slow` | `420ms` | hero 등장 |
| `spring/orbit` | `medium bouncy` | 현재 시점, active 강조 |

모션 규칙:

- 항상 움직이지 않는다.
- 현재 시점, 상태 전환, 시트 등장에만 사용한다.
- 장식용 모션은 금지한다.

## 8. Component Standards

### 8.1 Orbit Components

- `CircularTimetableArea`

원형 시간표의 중앙은 **시계 하나만** 맡는다. 현재 루틴 이름은 화면 상단
포커스 스트립이 이미 말하고 있으므로 중앙에서 반복하지 않는다.

규칙:

- Orbit 계열 컴포넌트는 홈과 미리보기에서만 강하게 사용한다.
- 일반 설정 화면까지 원형 메타포를 확장하지 않는다.

### 8.2 Form Components

- `PastelColorPalette`
- `PastelSwitchTile`
- `AppFieldMessage`
- `AppButton`

규칙:

- 입력은 `라벨 -> 컨트롤 -> 메시지` 순서를 지킨다.
- 에러는 인라인으로 먼저 보여준다.

### 8.3 Layout Components

- `AppScreenShell`
- `AppPageHeader`
- `AppCard` / `appSurfaceDecoration`
- `AppStatusBadge`
- `OrbitBottomNavigation`

규칙:

- 최대 폭은 `AppLayout.maxContentWidth`
- 기본 수평 패딩은 `AppSpacing.screenHorizontal`
- CTA 높이는 기본 `56`

## 9. Screen Templates

### 9.1 Home

```text
Header
Focus Strip (NOW / NEXT)
Hero Orbit
Slot Actions (완료 / 나중에 / 스킵)
Upcoming List
```

포커스 스트립의 배지는 진행 중이면 `NOW`, 아직 시작 전이면 `NEXT`다.
현재 루틴이 없는데 `NOW`를 붙이면 화면이 사실과 다른 말을 한다.

### 9.2 Routine Add / Edit

```text
Page Header
Preview Hero
Identity
Time Block
Repeat
Color Mood
Notification
Validation Summary
Save Bar
```

### 9.3 Progress

```text
Headline
Primary Metric
Trend / Summary
Supporting Breakdown
```

## 10. Copy Guidelines

좋은 예:

- `오늘의 궤도`
- `집중 블록 종료까지 20분`
- `다음 전환은 18:00`
- `하루에 자연스럽게 배치해보세요`

피해야 할 예:

- 너무 긴 감성 문장
- 기능보다 분위기만 전달하는 문구
- 화면마다 다른 말투

카피 규칙:

- 짧게
- 명확하게
- 행동과 상태 중심

## 11. Accessibility

- 본문 텍스트는 가능하면 `13sp` 미만으로 내리지 않는다.
- 색만으로 상태를 구분하지 않는다.
- 아이콘 버튼은 최소 `44x44` 터치 영역을 확보한다.
- 원형 차트의 상태는 반드시 텍스트로도 보조한다.

## 12. Adoption Plan

1. 홈 hero 구조를 V2 기준으로 고정 — 완료
2. 루틴 추가 화면의 preview hero 우선 적용 — 완료
3. 색상 토큰을 `AppColors` 에 단계적으로 흡수 — 완료
4. 공용 section header / status pill 정리 — 완료
5. 진행률 화면과 설정 화면 톤 정렬 — 완료
6. 온보딩·최초 설정·알림 권한 화면 톤 정렬 — 완료

온보딩 미리보기는 목업을 새로 그리지 않고 실제 화면 위젯
(`CircularTimetableArea`, `AppButton`)을 그대로 쓴다. 목업을 따로 두면
화면이 바뀔 때마다 온보딩만 뒤처져 없는 UI를 약속하게 된다.

## 13. Out of Scope

이번 V2 초안에는 아래 항목은 포함하지 않는다.

- 다크 모드 전면 재설계
- 태블릿 전용 레이아웃 분기
- 애니메이션 상세 스펙 문서
- 마케팅 사이트 또는 스토어 이미지 제작 파일
