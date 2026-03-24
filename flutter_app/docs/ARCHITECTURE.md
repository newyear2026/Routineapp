# Routine Timer — 프로젝트 구조 & 핵심 로직

하루 24시간 원형 시간표 기반 루틴 앱. **UI ↔ 애플리케이션(상태/ViewModel) ↔ 도메인 서비스 ↔ 저장소(Repository)** 로 분리하고, 저장 구현체만 교체해 서버/DB로 확장할 수 있게 한다.

---

## 1. 폴더 구조 (제안)

```
lib/
├── domain/                      # 비즈니스 규칙, Flutter UI 비의존
│   ├── models/                  # Routine, RoutineLog, AppSettings, WatchState, enum
│   ├── services/               # RoutineScheduleService, RoutineProgressService, RoutineDayService(파사드)
│   └── utils/                   # TimeMinutes, TimeCalculation
├── data/
│   ├── repositories/            # 추상 인터페이스만
│   ├── local/                   # SharedPreferences 등 로컬 구현
│   └── seed/                    # 초기 데이터
├── application/
│   ├── home/                    # HomeSnapshot, HomeSnapshotBuilder
│   ├── mappers/                 # domain → UI 모델 변환
│   ├── services/                # RoutineDataService 등 — Repository 조합, UI는 여기만 의존
│   └── *_controller.dart        # ChangeNotifier / 상태 조합
├── models/                      # 위젯 전용 DTO (RoutineSegment, CurrentRoutine …)
├── screens/ , widgets/          # 표현 계층
└── theme/
```

**서버 확장 시**: `data/remote/` 에 `RemoteRoutineRepository`, `RemoteRoutineLogRepository`, `SyncCoordinator` 를 두고 각 Repository 인터페이스 구현을 합성(캐시 + API)한다.

---

## 2. 타입 정의 (요약)

| 타입 | 파일 | 역할 |
|------|------|------|
| **Routine** | `domain/models/routine.dart` | 루틴 정의: 제목, 분 단위 시작/끝, 반복 요일, 색, 이모지, 알림 여부 |
| **RoutineLog** | `domain/models/routine_log.dart` | 특정 날짜의 실행 기록: `routineId`, `dateYmd`, `status`, `completedAtMs`, `snoozedUntilMs` |
| **RoutineLogStatus** | `domain/models/routine_log_status.dart` | scheduled, active, completed, snoozed, skipped, noResponse, expired |
| **AppSettings** | `domain/models/app_settings.dart` | 소리/푸시, 테마 id, 온보딩·권한 플래그 |
| **WatchState** | `domain/models/watch_state.dart` | 페어링, 연결, 마지막 동기 시각, 기기 id |

---

## 3. 시간 계산 유틸

- **`TimeMinutes`** (`domain/utils/time_minutes.dart`): 분 단위 변환, `HH:mm`, `yyyy-MM-dd`
- **`TimeCalculation`** (`domain/utils/time_calculation.dart`): 같은 날 구간 `[start, end)` 포함 여부, 창구 내 경과 비율 (자정 넘김은 MVP 제외)

---

## 4. 서비스 계층 (역할 분리)

| 서비스 | 책임 |
|--------|------|
| **RoutineScheduleService** | 요일 필터, 정렬, **현재 루틴**, **다음 루틴**, 리스트 순서상 다음 슬롯 |
| **RoutineProgressService** | **오늘 완료/전체** 수, **창구 내 진행 %** |
| **RoutineDayService** | 기존 코드 호환용 **파사드** (위 두 서비스에 위임) |

---

## 5. Repository 인터페이스 (저장소)

저장 **엔티티**별로 인터페이스를 나누어, 나중에 서버/API 구현체로 교체할 때 단일 책임으로 스왑한다.

### 루틴 정의
- **`RoutineRepository`** (`data/repositories/routine_repository.dart`): `loadRoutines`, `saveRoutines`
- **로컬**: `LocalRoutineRepository` — 키 `domain.routines.v1` (SharedPreferences JSON)

### 루틴 로그
- **`RoutineLogRepository`** (`data/repositories/routine_log_repository.dart`): `loadLogsForDate`, `upsertLog`, `loadAllLogs`
- **로컬**: `LocalRoutineLogRepository` — 키 `domain.routine_logs.v1`

### 설정 + 워치 상태
- **`SettingsRepository`** (`data/repositories/settings_repository.dart`): `loadAppSettings` / `saveAppSettings`, `loadWatchState` / `saveWatchState`
- **로컬**: `LocalSettingsRepository`

### 애플리케이션 서비스 (Repository 소비)
- **`RoutineDataService`** (`application/services/routine_data_service.dart`): 홈·루틴 흐름용으로 `RoutineRepository` + `RoutineLogRepository` 를 한 곳에서 주입·호출. **`RoutineAppController`** 는 이 서비스만 사용해 SharedPreferences 등 구현 세부에 의존하지 않는다.

**서버 확장**: 동일 인터페이스를 구현하는 `ApiRoutineRepository` + 오프라인 큐, 또는 `CachedRoutineRepository` 가 로컬 캐시 + 원격을 감싼다.

---

## 6. UI 계층 vs Service

- **화면/위젯**: `Routine`, `RoutineLog` 를 직접 조합하지 않고, **Controller**가 **ViewModel** 또는 기존 UI DTO(`CurrentRoutine`, `RoutineSegment`)로 변환해 전달한다.
- **액션** (완료/스누즈/스킵): UI → Controller → `RoutineDataService.upsertLog` + `notifyListeners`

---

## 7. ViewModel 관점 — 화면이 받아야 할 데이터

### 홈 (`HomeSnapshot` — `application/home/home_snapshot.dart`)

| 필드 | 의미 |
|------|------|
| `todayRoutines`, `currentRoutine`, `nextRoutine` | 도메인 루틴 |
| `dayProgressPercent` / `progressPercent`, `completedCount`, `totalCount` | 오늘 진행 |
| `currentRoutineLogStatus`, `currentRoutineStatusLabel` | 현재 슬롯 루틴 상태 |
| `dateLabel`, `dayOfWeekLabel`, `greeting` | 헤더 |
| `homeProgress` | 헤더 진행 바용 |
| `clockTime`, `centerRoutineName`, `segments`, `activeRoutineForRing` | 원형 시간표 |
| `currentRoutineCard`, `nextRoutineCard`, `character` | 카드·캐릭터 |
| `isDisplayUpcoming`, `completeButtonLabel`, `canActOnCurrentSlot` | CTA |
| `isEmptyDay` | 오늘 루틴 없음 |

**원칙**: 위젯은 **이 스냅샷만** 받아 그린다. “지금이 몇 번째 루틴인지” 같은 계산은 **Service + Controller**에만 둔다.

### 설정 화면 (예시)

- `AppSettings` + `WatchState` (또는 `SettingsViewModel` 로 묶기)
- 토글 변경 시 `SettingsRepository.saveAppSettings` → `notifyListeners`

### 진행 화면

- `List<Routine>` + 당일 `List<RoutineLog>` 또는 미리 계산된 `DailyProgressViewModel`

---

## 8. 데이터 흐름 (한 줄)

```
Repository → Application Service(저장 조합) → Controller → Domain Service(계산) → Mapper → ViewModel/UI DTO → Widget
```

이 문서는 구현과 함께 갱신되며, 새로운 화면은 **ViewModel 타입 추가**를 먼저 정의하는 것을 권장한다.
