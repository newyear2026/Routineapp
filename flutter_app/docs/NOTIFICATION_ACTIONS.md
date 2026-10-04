# Android 루틴 알림 액션

루틴 시작 알림과 미루기 재알림에 실제 앱 아이콘, `확인했어요`, `15분 뒤 알림`을 표시한다.
버튼은 Android 시스템 알림의 펼친 상태에 나타나며, 잠금 화면 표시와 노출 범위는 기기 설정을 따른다.
한국어·영어·스페인어·일본어·포르투갈어를 지원한다.

## 동작

| 입력 | 결과 |
| --- | --- |
| 확인했어요 | 전달된 알림만 닫는다. 완료 기록이나 다음 주 반복 예약은 바꾸지 않는다. |
| 15분 뒤 알림 | 해당 날짜·루틴을 미루기로 기록하고 누른 시각에서 15분 뒤 한 번 재알림한다. 앱을 열지 않는다. |
| 알림 본문 | 알림을 보낸 루틴의 확인 화면을 연다. 같은 시간에 겹친 다른 루틴으로 이동하지 않는다. |
| 확인 화면의 완료 버튼 | 현재 유효한 해당 루틴만 완료 처리한다. 되돌리기도 제공한다. |

지난 날짜, 종료된 시간, 삭제·수정된 루틴의 오래된 알림은 새 기록을 만들지 않는다.
이미 완료하거나 건너뛴 기록도 미루기로 덮어쓰지 않는다.
미리보기 알림에는 실재하는 루틴이 없으므로 확인 버튼만 제공한다.

## 구현 경계

- `NotificationRuntime`이 플러그인 초기화·시작 알림·실행 중 탭·백그라운드 액션을 소유한다.
  권한 조회가 콜백을 재초기화하지 않는다.
- `RoutineNotificationTarget`은 루틴 ID, 버전, 시간과 요일 또는 날짜를 담는다.
  반복 알림의 발생 날짜는 Android가 기록한 게시 시각으로 계산한다.
- `NotificationActionService`가 유효성을 확인하고 기존 `RoutineLogActionService`로 미루기 기록을 만든다.
- 로컬 `routine_notification_platform` 플러그인은 Activity 없이도 백그라운드 Flutter 엔진에 등록된다.
  게시 시각 조회, 전달 알림만 닫기, 시간대·정확 알람 권한 조회, 기록의 원자적 저장을 담당한다.
  Android가 이전 태스크를 복원한 뒤 알림 Intent를 보낼 때도 날짜를 잃지 않도록,
  Activity 연결 시 활성 알림의 게시 시각을 먼저 보관한다.
- 알림 확인에는 `NotificationManager.cancel`만 사용한다. 일반 알림 플러그인의 `cancel`은 같은 ID의
  다음 주 알람까지 취소하므로 사용하지 않는다.
- Android의 모든 루틴 기록 쓰기는 네이티브 저장 잠금을 공유한다. 별도 엔진의 캐시가 완료 기록이나
  다른 루틴 기록을 덮어쓰지 않도록 하며, 메인 화면은 변경 통지와 앱 복귀 때 기록을 다시 읽는다.
- 새 버튼은 Android 구현이다. iOS 알림 액션 카테고리는 추가하지 않았다.

## 검증

자동 테스트는 오래된 알림, 겹친 루틴, 중복 응답, 완료와 미루기의 경쟁, 자정을 넘는 재예약,
삭제된 루틴 화면, 완료 버튼 대상, 기존 주간 예약 보존을 다룬다.

2026-10-04: 최종 관련 테스트 68개, 변경 소스의 정적 검사, Android debug APK 빌드를 통과했다.
Android 16 / API 36 에뮬레이터에서 다음을 확인했다.

- 실제 앱 아이콘과 두 알림 버튼 표시.
- 앱 화면을 열지 않는 백그라운드 미루기: 누른 시각 14:20:09 → 14:35:09 재예약,
  해당 루틴의 `snoozed` 기록 저장, 주간 예약 21개와 재알림 1개 공존.
- 확인 버튼: 알림만 제거, 기존 기록과 주간 예약 유지.
- 프로세스가 없는 상태의 본문 탭: 날짜와 완료 버튼이 있는 해당 루틴 화면으로 이동.
- 같은 시간에 겹친 다른 루틴 대신 알림에 표시된 루틴만 완료 기록.

15분이 실제 경과한 뒤의 재발화와 실물 제조사별 잠금 화면 배치는 이번 검증 범위에 포함하지 않았다.

```sh
flutter test test/notification_actions_test.dart test/notification_routine_screen_test.dart \
  test/routine_notification_service_test.dart test/notification_modes_test.dart \
  test/notification_icon_resource_test.dart test/snooze_reminder_test.dart \
  test/routine_app_controller_test.dart test/notification_settings_screen_test.dart \
  test/notification_boot_receiver_test.dart test/settings_controller_test.dart \
  test/notification_onboarding_actions_test.dart
```

2026-10-04 초기 전체 테스트 실행에서 발견한 기존 실패 4건은 변경 전 HEAD에서도 재현했다:
홈 스낵바 2건, 푸들 루틴 화면의 애니메이션 대기, 팩 구매 화면의 중복 문구 기대값.
그 전체 실행의 진행 화면 테스트는 종료되지 않아 전체 통과로 판정하지 않았다.
이후 관련 테스트를 현재 작업 파일 기준으로 다시 실행해 위의 68개 통과를 확인했다.
