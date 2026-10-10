# LOOPET Firebase 운영

## 공용 프로젝트

- 프로젝트: `cs-project-nuszgcho`
- [Firebase 콘솔](https://console.firebase.google.com/project/cs-project-nuszgcho/overview)
- 기존 RandomFocus Android/iOS 등록은 유지한다. 프로젝트·기존 앱·기존 GA 데이터는 삭제하지 않는다.
- LOOPET Android 패키지: `com.dayround.app`
- Firebase 앱 ID: `1:96665827051:android:895fdeb34e6799a2f030ae`
- GA4 속성: `547528956`, LOOPET 스트림 ID: `16043136860`
- RandomFocus Android 스트림: `15342612731`, iOS 스트림: `15342595842`

Crashlytics에서 `LOOPET Android` 앱을 선택한다. Analytics의 전체 보고서는 여러 앱을
포함하므로 LOOPET 스트림으로 필터링한다. 프로젝트 공용 이름·보존 기간·Ads 연결·
다른 앱 설정은 이번 연결에서 변경하지 않았다.

## 앱 설정

`firebase_options.dart`, `android/app/google-services.json`, `firebase.json`은
LOOPET 등록에서 생성했다. 서비스 계정 키나 로그인 토큰을 저장소에 넣지 않는다.
이 Firebase 클라이언트 설정은 공개 식별 정보이며, RandomFocus 설정 파일을 복사하지 않는다.

Android에서만 초기화한다. 웹·데스크톱·iOS 미리보기와 단위 테스트는 수집하지 않는다.
릴리스 빌드는 수집을 켜고, 디버그/프로파일 빌드는 기본적으로 끈다.
`--dart-define=TELEMETRY_ENABLED=true`로 테스트 수집을 켤 수 있고,
`--dart-define=TELEMETRY_ENABLED=false`로 릴리스 수집도 끌 수 있다.
기기에서 런타임 설정은 유지될 수 있으므로 테스트 후 일반 디버그 빌드를 다시 실행한다.

Analytics의 광고 ID 수집과 광고 목적 동의 값은 꺼져 있다. AdMob UMP 절차는 유지한다.
이 설정이 별도의 Analytics 동의 화면을 제공하는 것은 아니다. 배포 대상에 맞는 사용자
안내·수집 선택 정책은 공개 개인정보처리방침과 함께 검토한다.

## 수집 이벤트

| 이벤트 | 시점 / 파라미터 |
|---|---|
| `screen_view` | 이름이 정해진 Flutter 화면 방문. `screen_name`, `screen_class` |
| `routine_created`, `routine_updated`, `routine_deleted` | 저장 성공 후 |
| `routine_completed`, `routine_snoozed`, `routine_skipped` | 액션 저장 성공 후. `action_source`: `app` 또는 `notification` |
| `routine_action_undone` | 되돌리기 저장 성공 후 |

첫 실행·세션 등은 SDK 자동 이벤트를 사용한다. 앱 내부 컨트롤러를 거치는 동작만
맞춤 이벤트로 기록한다. 백그라운드 알림 엔진에서 직접 수행하는 액션은 아직 포함하지 않는다.
완료 이벤트 수는 행동 횟수이며, 되돌리기가 있으므로 최종 완료 루틴 수와 같지 않다.
루틴의 제목·메모·ID·시각·알림 payload 및 구매 영수증은 맞춤 파라미터로 보내지 않는다.
사용자 계정 ID는 설정하지 않는다.

Flutter 프레임워크 오류는 non-fatal, 처리되지 않은 비동기 오류는 fatal로 보고한다.
저장 오류도 non-fatal로 보고하며, 원문에 루틴 데이터가 포함될 수 있어 오류 타입과
스택만 보낸다. Firebase 초기화나 전송 실패가 루틴 저장 결과를 바꾸지 않는다.

## 검증

```sh
flutter test test/app_telemetry_test.dart test/routine_app_controller_test.dart test/onboarding_flow_test.dart test/privacy_policy_link_test.dart
flutter analyze lib test/app_telemetry_test.dart tool/firebase_smoke.dart
adb shell setprop debug.firebase.analytics.app com.dayround.app
flutter run --dart-define=TELEMETRY_ENABLED=true
```

Firebase Analytics의 DebugView에서 LOOPET 기기의 화면 이벤트를 확인한다.
실제 앱을 다시 실행한 뒤 Crashlytics에서 오류를 확인한다.

테스트용 기기에서만 별도 진입점으로 강제 충돌을 발생시킨다. 기존 앱 데이터는 유지한다.

```sh
flutter run -t tool/firebase_smoke.dart --dart-define=TELEMETRY_ENABLED=true --dart-define=FIREBASE_TEST_CRASH=true
# 다음 실행은 정상 진입점으로 돌아오며, 저장된 보고서를 업로드한다.
flutter run --dart-define=TELEMETRY_ENABLED=true
adb shell setprop debug.firebase.analytics.app .none.
```

테스트 이벤트는 `loopet_telemetry_test`이다. 테스트 진입점은 기본 릴리스 빌드에 포함되지 않는다.
DebugView 지정은 테스트 데이터가 일반 Analytics 보고서를 오염시키는 것을 줄인다.
Crashlytics에는 테스트 오류가 나타나므로 실제 사용자 오류와 구분한다.

릴리스 빌드: `flutter build appbundle --release`. 프로덕션 광고 플래그는
`PLAY_STORE_RELEASE.md`를 따른다. 난독화 또는 `--split-debug-info`를 추가한다면
[공식 문서](https://firebase.google.com/docs/crashlytics/flutter/get-started)에 따라
Android Dart 심볼도 별도 업로드한다.

배포 전 `PRIVACY_POLICY.md`와 루트 `docs/privacy/index.html`의 변경을 공개 페이지에
게시하고 Play Console 데이터 안전성을 갱신한다. 앱 등록만으로 기존 설치본의 수집이
시작되지는 않으며 이 SDK를 포함한 새 버전이 설치되어야 한다.

## 연결 검증 기록 — 2026-10-04

- Firebase 앱 목록에서 RandomFocus Android/iOS와 LOOPET Android가 모두 ACTIVE임을 확인.
- Firebase Management API에서 LOOPET의 GA4 스트림 연결을 확인.
- 관련 테스트 26개 통과. 앱 소스·새 테스트·검증 진입점 정적 분석 통과.
- Android 디버그 APK 및 릴리스 AAB 빌드 성공.
- 에뮬레이터의 `screen_view`, `loopet_telemetry_test` 업로드에 Analytics HTTP 204 응답 확인.
- Crashlytics 전송 HTTP 200 응답과 서버 Top Issues 보고서의 테스트 NON_FATAL 1건,
  FATAL 1건 수신 확인. 이 두 건은 사용자 장애가 아니라 연결 검증용 오류다.
- 공개 개인정보처리방침 게시, Play Console 설문 수정, 새 앱 버전 배포는 수행하지 않음.

## 연결 재검증 기록 — 2026-10-05

- LOOPET Android의 네이티브·Dart Firebase 앱 ID와 GA4 스트림 연결을 다시 확인.
- 관련 자동 테스트 26개와 앱 소스·검증 진입점 정적 분석 통과.
- 임시 Android 에뮬레이터에서 `loopet_telemetry_test`와 `splash`, `onboarding`
  화면 이벤트를 전송하고 Analytics HTTP 204 응답 확인.
- Crashlytics 업로드 HTTP 200 응답 및 서버 Top Issues 보고서에서 NON_FATAL과
  FATAL 테스트 오류가 각각 1건에서 2건으로 증가한 것을 확인. 두 이슈의 최신
  샘플 이벤트가 이번 테스트 세션 `6AC3F5F800D900010F2A3F8514E49C23`과 일치.
- 기본 디버그 APK를 다시 빌드·설치·실행하여 Analytics의 `measurement_enabled`와
  Crashlytics의 `firebase_crashlytics_collection_enabled`가 모두 `false`임을 확인.
- 실제 기기 검증과 릴리스 AAB 재빌드는 이번 재검증 범위에 포함하지 않음.
