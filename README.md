# Routine Timer (Flutter)

귀엽고 감성적인 **하루 루틴 시간표** 모바일 앱입니다.  
Figma 디자인([Cute Emotional Routine App UI](https://www.figma.com/design/7u3ixFSgljZPwdJwxdYuYp/Cute-Emotional-Routine-App-UI))을 기준으로 Flutter로 구현합니다.

**저장소**: [github.com/newyear2026/Routineapp](https://github.com/newyear2026/Routineapp)

## 요구 사항

- Flutter SDK 3.x
- Dart 3.x (`sdk: '>=3.0.0 <4.0.0'`)

## 실행

```bash
cd flutter_app
flutter pub get
flutter run
```

기기/에뮬레이터 목록: `flutter devices`  
웹(Chrome): `flutter run -d chrome`  
Windows 데스크톱: `flutter run -d windows`

## 현재 구현 요약

- **데이터·저장**: `Routine` / `RoutineLog` 도메인 모델, **로컬 전용**(`SharedPreferences`) — Repository 계층으로 접근 (`RoutineRepository`, `RoutineLogRepository`, `SettingsRepository`).
- **앱 상태**: `RoutineAppController`(Provider)에서 로드·저장, 홈/진행/설정과 연동.
- **시간·스케줄**: 분 단위 유틸, 오늘 루틴 필터, **현재/다음 루틴** 계산, 진행률·일별 로그 액션(완료·스누즈·스킵 등).
- **루틴 편집**: 루틴 **추가·수정** 화면, 시간대 **겹침 경고**(저장 전 확인 가능).
- **홈 원형 시간표**: 24시간 **동심원 도넛** 링, 시간 가이드선, 루틴 구간 색상, **구간 시작·종료 경계선**(가이드보다 선명하게, 활성 루틴 경계 추가 강조), 현재 시각 표시.
- **홈 위젯**: `home_widget` 기반 동기화·미디엄 위젯용 구조 및 **미리보기** 라우트(네이티브 위젯 설정은 플랫폼별).

MVP 범위·아키텍처 규칙은 **`PROJECT_RULES.md`** 를 따릅니다.

## 프로젝트 구조

- `flutter_app/lib/` — 앱 소스
  - `main.dart`, `screens/` — 화면·라우팅
  - `application/` — 컨트롤러, 홈 스냅샷, 매퍼
  - `domain/` — 모델, 서비스(스케줄·로그·진행·충돌 등), 유틸
  - `data/` — 로컬 Repository 구현, 시드
  - `models/` — 화면용 모델(홈·진행 등)
  - `widgets/`, `theme/` — UI·테마
  - `widget_home/`, `widget_medium/` — 홈 위젯 연동·미디엄 위젯 UI
- `flutter_app/pubspec.yaml` — 의존성

이 저장소의 **단일 앱은 Flutter**입니다. (이전 웹/React 번들은 제거되었습니다.)

루트에 예전 `node_modules` 폴더가 남아 있으면(파일 잠금 등으로 삭제 실패 시) IDE를 닫은 뒤 폴더를 수동으로 지우거나, 사용하지 않아도 빌드에는 영향 없습니다.

## 주요 의존성

| 패키지 | 용도 |
|--------|------|
| `provider` | 상태 관리 |
| `go_router` | 라우팅 |
| `shared_preferences` | 로컬 저장 |
| `flutter_local_notifications` | 로컬 알림 |
| `intl` | 날짜/시간 포맷 |
| `home_widget` | 홈 화면 위젯 연동 |
| `flutter_animate`, `lottie` | UI 애니메이션 |

## 라우트

| 경로 | 화면 |
|------|------|
| `/` | 스플래시 |
| `/onboarding` | 온보딩 |
| `/notification-permission` | 알림 권한 |
| `/routine-setup` | 초기 루틴 설정 |
| `/home` | 홈 |
| `/progress` | 오늘 진행 |
| `/settings` | 설정 |
| `/routine-add` | 루틴 추가·수정 (`?id=` 로 수정) |
| `/widget-medium-preview` | 미디엄 위젯 미리보기 |

## 문서

- `PROJECT_RULES.md` — 제품 범위, 데이터·아키텍처·시간 계산 규칙
- `flutter_app/README.md` — Flutter 앱 상세 안내(실행·구조·디자인 시스템 등)
