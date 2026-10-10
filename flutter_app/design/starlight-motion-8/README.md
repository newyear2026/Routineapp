# 별빛 고양이 · 홈 8프레임 모션

## 멈춤 자세 제거 · 2026-10-07

걷기 시트를 반복 전용 8프레임으로 다시 제작했다. 첫·마지막 프레임에 앉은 대기 그림을
넣지 않으며, 모든 프레임을 120ms로 표시해 0.96초마다 연결한다. 기존 시트·생성 기록은
보관용이며 앱에서는 `walk_loop_8.png`를 사용한다.
[새 걷기 원본·프롬프트·검증](../home-walk-loop-8/README.md) · [이 캐릭터 프롬프트](../home-walk-loop-8/starlight/IMAGEGEN_PROMPT.txt)

## 집중 시간 반복 재생 · 2026-10-07

진행 중에는 걷기 8프레임을 계속 반복한다. 예정/미룸/건너뜀으로 바뀌면 걷기를 멈추고,
완료 전환에서는 축하를 한 번 재생한 뒤 마지막 자세를 유지한다. 진행 중 화면 재진입,
완료 취소 및 백그라운드/탭 복귀 시에는 현재 상태에 맞춰 걷기를 재개한다.
동작 줄이기 설정에서는 걷지 않는다. 이전 원본은 보존했으며, 현재 걷기는 별도의 반복 전용 시트를 사용한다.
9종 반복 재생·상태 전환·실제 홈 렌더링을 포함한 94개 테스트와 변경 Dart 19개 파일의
정적 분석이 통과했다. Android debug 빌드도 성공했다.

2026-10-06. 기본 별빛 고양이(`cat_starlight`)의 대기·루틴 시작·완료 모션.
기존 원화의 귀, 이마 무늬, 청록 목걸이와 네모 금색 장식을 유지했다.

| 모션 | 동작 | 앱 재생 | 미리보기 |
|---|---|---|---|
| 대기 | 눈 깜빡임, 꼬리 흔들기 | 4초 루프 | [캐릭터](idle/character-preview.gif) · [홈 카드](idle/card-preview.gif) |
| 시작 | 오른쪽으로 돌아 제자리 걷기 후 앉기 | 진행 중 0.96초 주기로 반복 | [캐릭터](walk/character-preview.gif) · [홈 카드](walk/card-preview.gif) |
| 완료 | 작은 점프, 앞발 들어 축하, 웃으며 앉기 | 1.2초 한 번, 마지막 표정 유지 | [캐릭터](complete/character-preview.gif) · [홈 카드](complete/card-preview.gif) |

걷기 GIF는 앱과 같은 속도로 반복한다. 완료 GIF에만 검수용 2초 대기와 반복을 적용한다.
앱에서는 진행 중 걷기를 반복하고 완료 모션은 한 번만 재생한다.

## 앱 자산

- [대기 시트](../../assets/characters/cat_starlight/v1/motion/idle_8.png)
- [걷기 시트](../../assets/characters/cat_starlight/v1/motion/walk_loop_8.png)
- [완료 시트](../../assets/characters/cat_starlight/v1/motion/complete_8.png)

각각 1536×768 RGBA PNG, 4열×2행, 셀당 384×384.
왼쪽에서 오른쪽, 위에서 아래 순서다. 개별 프레임은 각 모션의 `frames/`에 있다.
시작·완료의 첫 프레임과 걷기의 마지막 프레임은 대기의 중립 프레임과 동일하다.
각 셀과 전체 캐릭터 영역을 함께 클리핑하고 바닥선을 고정한다.

## 생성과 검수

내장 ImageGen으로 원화와 스프라이트를 만들었다. Swift는 셀 분리, 균일한
nearest-neighbor 크기 조절, 바닥 정렬, GIF 인코딩만 수행한다.

최종 프롬프트 세트:
- [대기](idle/IMAGEGEN_PROMPT.txt)
- [걷기](walk/IMAGEGEN_PROMPT.txt)
- [완료](complete/IMAGEGEN_PROMPT.txt)
- [완료 7번 프레임의 중복 앞발 수정](complete/REPAIR_PROMPT.txt)

완료 7번은 초기 생성본에 앞발이 중복되어 있었다. 내장 ImageGen으로 중앙의
중복 바닥 발을 제거하고, 든 앞발 2개와 바닥의 뒷발 2개만 남겼다.
`complete/source/repaired-frame-07.png`가 앱에 들어가는 수정 원본이다.
`rejected-frame-07-six-paws.png`는 오류 기록이며 앱에서 사용하지 않는다.
24프레임을 시각적으로 확인하고, PNG 크기·투명도·각 셀의 이미지 존재를 검사했다.

## 재생 규칙

마법사 고양이와 `HomeCharacterMotion` 재생기를 공유한다.
- 예정→진행 중, 미룸→진행 중, 다른 날짜/루틴의 시작에서 걷기를 재생한다.
- 같은 루틴의 진행 중/미룸→완료에서 축하를 재생한다.
- 이미 진행 중인 홈으로 들어오면 걷기를 반복하고, 이미 완료됐으면 마지막 웃는 프레임을 표시한다.
- 완료 취소나 화면 재생성 때문에 이벤트를 다시 재생하지 않는다.
- 숨겨진 화면·백그라운드·동작 줄이기에서는 모션을 중단하고, 복귀 시 지난 이벤트를 재생하지 않는다.
- 미룸·빈 화면의 휴식/안내 포즈는 기존 원화를 유지한다.

## 재현과 검증

`flutter_app`에서 실행:

```sh
swift -module-cache-path /private/tmp/loopet-swift-cache tool/export_starlight_motion_atlases.swift
flutter test --no-pub tool/render_starlight_motion_preview.dart
swift -module-cache-path /private/tmp/loopet-swift-cache tool/encode_starlight_motion_previews.swift
flutter test --no-pub test/starlight_home_motion_test.dart test/stargazer_home_motion_test.dart test/home_screen_test.dart test/home_cat_pose_test.dart
```

모션·홈 연결·실제 HomeScreen 렌더링을 포함한 37개 테스트 통과. 변경한 Dart
8개 파일의 정적 분석 통과. 홈 렌더링은 메모리 저장소에서 시각 변경과 실제
완료 액션을 통해 세 모션을 캡처하며, 사용자의 루틴 기록은 변경하지 않는다.

최신 debug APK를 Pixel 3 에뮬레이터에 기존 데이터를 유지해 설치했다.
별빛 고양이 선택 상태와 실제 홈의 눈 깜빡임·꼬리 움직임을 확인했으며,
[적용 영상](home-applied-emulator.mp4)을 저장했다. 실기기 설치는 수행하지 않았다.
