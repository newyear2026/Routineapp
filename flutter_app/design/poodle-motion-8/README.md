# 푸들 정원 · 홈 8프레임 모션

## 멈춤 자세 제거 · 2026-10-07

걷기 시트를 반복 전용 8프레임으로 다시 제작했다. 첫·마지막 프레임에 앉은 대기 그림을
넣지 않으며, 모든 프레임을 120ms로 표시해 0.96초마다 연결한다. 기존 시트·생성 기록은
보관용이며 앱에서는 `walk_loop_8.png`를 사용한다.
[새 걷기 원본·프롬프트·검증](../home-walk-loop-8/README.md) · [이 캐릭터 프롬프트](../home-walk-loop-8/poodle/IMAGEGEN_PROMPT.txt)

## 집중 시간 반복 재생 · 2026-10-07

진행 중에는 걷기 8프레임을 계속 반복한다. 예정/미룸/건너뜀으로 바뀌면 걷기를 멈추고,
완료 전환에서는 축하를 한 번 재생한 뒤 마지막 자세를 유지한다. 진행 중 화면 재진입,
완료 취소 및 백그라운드/탭 복귀 시에는 현재 상태에 맞춰 걷기를 재개한다.
동작 줄이기 설정에서는 걷지 않는다. 이전 원본은 보존했으며, 현재 걷기는 별도의 반복 전용 시트를 사용한다.
9종 반복 재생·상태 전환·실제 홈 렌더링을 포함한 94개 테스트와 변경 Dart 19개 파일의
정적 분석이 통과했다. Android debug 빌드도 성공했다.

2026-10-06. 기존 `poodle_garden` 캐릭터에 대기·루틴 시작·완료 모션을 추가했다.
살구색 곱슬 털, 늘어진 귀, 크림색 가슴과 발끝, 청록 목걸이와 금색 태그를 유지했다.

| 모션 | 동작 | 앱 재생 | 미리보기 |
|---|---|---|---|
| 대기 | 눈 깜빡임, 귀와 꼬리의 작은 움직임 | 4초 반복 | [캐릭터](idle/character-preview.gif) · [홈 카드](idle/card-preview.gif) |
| 시작 | 오른쪽으로 가볍게 제자리 걷기 후 앉기 | 진행 중 0.96초 주기로 반복 | [캐릭터](walk/character-preview.gif) · [홈 카드](walk/card-preview.gif) |
| 완료 | 귀를 팔랑이며 작은 점프 후 웃기 | 1.2초 한 번 → 마지막 자세 유지 | [캐릭터](complete/character-preview.gif) · [홈 카드](complete/card-preview.gif) |

걷기 GIF는 앱과 같은 속도로 반복한다. 완료 GIF에만 검수용 2초 대기와 반복을 적용한다.
앱에서는 진행 중 걷기를 반복하고 완료 모션은 한 번만 재생한다.

## 자산과 프롬프트

내장 ImageGen으로 제작했다. 최종 프롬프트와 생성 원본은 각 모션 폴더에 저장했다.

- [대기 프롬프트](idle/IMAGEGEN_PROMPT.txt) · [앱 PNG](../../assets/characters/poodle_garden/v1/motion/idle_8.png)
- [걷기 프롬프트](walk/IMAGEGEN_PROMPT.txt) · [앱 PNG](../../assets/characters/poodle_garden/v1/motion/walk_loop_8.png)
- [완료 프롬프트](complete/IMAGEGEN_PROMPT.txt) · [앱 PNG](../../assets/characters/poodle_garden/v1/motion/complete_8.png)

앱 PNG는 각각 1536×768 RGBA, 4열×2행, 프레임당 384×384다.
왼쪽에서 오른쪽, 위에서 아래 순서로 읽는다. 개별 PNG는 `frames/`, 생성 원본은
`source/generated-sheet.png`, 실제 홈 화면 캡처는 `rendered/`에 있다.

모든 모션의 첫 프레임과 걷기·대기의 마지막 프레임은 같은 중립 그림을 사용한다.
Swift 내보내기는 셀 분리, 균일한 nearest-neighbor 축소, 바닥 정렬, 점프 위치
조절과 GIF 인코딩만 수행한다. 그림이나 다리를 코드로 새로 그리지 않았다.
24프레임의 팔다리를 시각적으로 검수했고, 시트의 각 셀이 개별 프레임과 픽셀 단위로
같으며 빈 프레임이 없고 중립 프레임이 완전히 일치하는 것도 확인했다.

## 앱 연결

`PoodleHomeMotion`이 기존 공통 `HomeCharacterMotion`을 사용한다.
예정/미룸→진행 중과 새로운 루틴 시작에서 걷기, 같은 루틴의 진행 중/미룸→완료에서
축하를 재생한다. 이미 진행 중인 홈으로 들어오면 걷기를 반복하고, 이미 완료됐다면
웃는 마지막 자세를 보여준다. 완료 취소나 화면 재생성으로 이벤트를 반복하지 않는다.
동작 줄이기, 숨겨진 화면과 백그라운드에서는 모션을 멈춘다.
미룸·빈 화면의 휴식/안내 자세와 기존 정원 배경은 유지한다.

## 검증과 재현

모션 3종, 기존 고양이 모션, 홈 화면, 푸들 시간대 배경과 실제 홈 렌더링을 포함한
48개 테스트 통과. 변경한 Dart 4개 파일의 정적 분석 통과.
렌더링 도구는 메모리 저장소로 시각 변경과 완료 액션을 실행하므로 사용자의 루틴
기록을 변경하지 않는다.

최신 debug APK를 Pixel 3 에뮬레이터에 기존 데이터를 유지해 설치했다.
APK 안의 푸들·별빛 고양이·마법사 고양이 9개 모션 시트가 작업 폴더의 최신 파일과
일치하는 것을 확인했다. 확인 당시 기기의 보유 목록에는 푸들이 없어, 기기에서
푸들을 선택한 상태의 재생은 확인하지 못했다. 세 모션의 시각 검증은 위의 실제
HomeScreen 렌더링으로 수행했다. 실기기 설치는 수행하지 않았다.

`flutter_app`에서:

```sh
swift -module-cache-path /private/tmp/loopet-swift-cache tool/export_poodle_motion_atlases.swift
flutter test --no-pub tool/render_poodle_motion_preview.dart
swift -module-cache-path /private/tmp/loopet-swift-cache tool/encode_poodle_motion_previews.swift
flutter test --no-pub test/poodle_home_motion_test.dart test/starlight_home_motion_test.dart test/stargazer_home_motion_test.dart test/home_screen_test.dart test/home_cat_pose_test.dart test/poodle_time_scene_test.dart
```
