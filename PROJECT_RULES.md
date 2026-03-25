# PROJECT_RULES.md

## 프로젝트 개요
이 프로젝트는 **"하루 루틴 시간표 앱" MVP**다.

핵심 목표는  
**하루 24시간을 원형 시간표로 보여주고, 현재 시간 기준으로 현재 루틴과 다음 루틴을 계산하며, 사용자가 루틴을 완료 / 나중에 / 스킵할 수 있게 하는 것**이다.

---

## 1. 제품 범위

### 포함 기능
- 루틴 생성 / 수정 / 삭제
- 오늘 루틴 필터링
- 현재 루틴 / 다음 루틴 계산
- 원형 시간표 표시
- 완료 / 나중에 / 스킵 상태 변경
- 진행률 계산
- 로컬 저장
- 휴대폰 위젯 확장을 고려한 구조

### 제외 기능
아래 기능은 현재 MVP 범위에 포함하지 않는다.
- 서버 DB
- 로그인 / 회원가입
- 워치 연동
- 소셜 기능
- 커뮤니티
- AI 추천
- 고급 통계
- 복잡한 알림 정책

**MVP 범위를 벗어나는 기능을 임의로 추가하지 않는다.**

---

## 2. 핵심 데이터 구조

### Routine
Routine은 루틴 정의 데이터다.

예시 필드:
- id
- title
- startTime
- endTime
- repeatDays
- color
- icon
- notificationEnabled
- updatedAt

### RoutineLog
RoutineLog는 특정 날짜의 루틴 실행 기록이다.

예시 필드:
- id
- routineId
- date
- status
- completedAt
- snoozedUntil
- skippedAt
- actionSource

### 규칙
- 상태는 **Routine이 아니라 RoutineLog 기준으로 관리한다**
- Routine과 RoutineLog를 혼합하지 않는다
- 같은 날짜의 같은 routineId에 대해 중복 RoutineLog가 생기지 않도록 한다

---

## 3. 상태값 규칙

허용 상태값:
- scheduled
- active
- completed
- snoozed
- skipped
- no_response
- expired

규칙:
- completed / snoozed / skipped 같은 **명시 액션 상태는 시간 기반 상태보다 우선한다**
- 화면 표시 상태는 Routine 자체가 아니라 RoutineLog + 현재 시간 계산 결과를 함께 반영한다

---

## 4. 아키텍처 규칙

프로젝트 구조는 아래를 따른다:

- screens
- components
- models
- repositories
- services
- utils
- hooks

규칙:
- 화면 컴포넌트 안에 저장 로직을 직접 넣지 않는다
- 화면 컴포넌트 안에 복잡한 시간 계산 로직을 직접 넣지 않는다
- 비즈니스 로직은 services 또는 utils에 둔다
- 저장소 접근은 repositories 계층만 사용한다
- UI / Service / Repository / Utils 계층을 분리한다

---

## 5. 로컬 저장 규칙

이 프로젝트는 **서버 없이 로컬 저장 기반**으로 구현한다.

필수 Repository:
- RoutineRepository
- RoutineLogRepository
- SettingsRepository

규칙:
- 화면 컴포넌트에서 storage를 직접 호출하지 않는다
- Repository를 통해서만 저장/조회한다
- 이후 서버 DB로 교체 가능하도록 저장소 구현과 UI를 분리한다

---

## 6. 시간 계산 규칙

시간 비교는 문자열 비교로 하지 않는다.  
항상 **분 단위 숫자 변환**을 사용한다.

필수 함수:
- timeToMinutes
- getTodayRoutines
- getCurrentRoutine
- getNextRoutine
- calculateProgress

규칙:
- 시간 계산은 utils 또는 services에 둔다
- 현재 루틴 / 다음 루틴 계산은 Home 화면 안에서 직접 처리하지 않는다

---

## 7. 원형 시간표 규칙

원형 시간표는 반드시 **정확한 동심원 도넛 구조**로 구현한다.

규칙:
- 24시간 기준 각도 계산 기반
- 모든 구간은 같은 중심점을 기준으로 나뉘어야 한다
- 찌그러진 shape나 임의 도형 겹치기 방식은 금지한다
- 원형 시간표는 별도 컴포넌트로 분리한다
- 현재 활성 루틴은 별도 강조 처리한다

---

## 8. 루틴 충돌 정책

시간 수정은 허용한다.  
루틴 시간대가 겹치는 것도 허용할 수 있다.  
단, 저장 전에 충돌 경고를 보여준다.

규칙:
- create / edit 모두 시간 수정 허용
- 다른 루틴과 시간이 겹치면 저장 전 충돌 경고 표시
- 사용자가 확인하면 그대로 저장 가능
- edit 모드에서는 자기 자신(id가 같은 루틴)은 충돌 검사에서 제외한다

우선순위 규칙:
- 겹치는 루틴이 여러 개일 경우 currentRoutine은 **updatedAt이 가장 최근인 루틴을 우선**한다

충돌 검사 로직과 currentRoutine 우선순위 로직은 분리한다.

---

## 9. UI 원칙

UI는 감성적이고 귀여운 톤을 유지한다.  
하지만 시각적 예쁨보다 **정보 우선순위**를 먼저 고려한다.

항상 먼저 보여야 하는 정보:
1. 현재 루틴
2. 현재 시간
3. 다음 루틴
4. 액션 버튼
5. 진행률
6. 캐릭터 / 장식 요소

규칙:
- 장식 요소는 정보 전달을 방해하지 않도록 최소화한다
- 현재 루틴 / 현재 행동 / 다음 루틴이 가장 먼저 읽히게 한다

---

## 10. 구현 순서

항상 아래 순서로 구현한다:

1. 타입 정의
2. utils
3. repositories
4. services
5. 저장 로직
6. Home 실데이터 연결
7. 현재 루틴 / 다음 루틴 계산
8. 상태 변경
9. 진행률
10. 설정
11. 위젯 확장 구조

한 번에 전체 앱을 갈아엎지 말고, 단계별로 안정적으로 구현한다.

---

## 11. 위젯 확장 원칙

워치 연동은 제외한다.  
대신 휴대폰 위젯 확장을 고려한다.

위젯이 사용할 수 있도록 아래 데이터를 쉽게 꺼낼 수 있는 구조를 유지한다:
- currentRoutine
- nextRoutine
- progressSummary

Home 전용 하드코딩 구조가 아니라, selector 또는 service 기반으로 재사용 가능하게 설계한다.
