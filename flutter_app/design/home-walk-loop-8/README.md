# 홈 캐릭터 연속 걷기 · 9종

2026-10-07. 진행 중에 걷다가 멈춰 보이던 구간을 수정했다.

이전 걷기 시트는 시작용 동작으로, 첫·마지막 프레임이 대기의 앉은 그림이고 끝부분도
정면으로 돌아오는 자세였다. 재생을 반복해도 매 주기마다 앉는 동작이 되었다.
내장 ImageGen으로 9종의 걷기를 각각 8프레임의 연속 보행으로 다시 제작했다.
앱에는 `walk_loop_8.png`를 연결하며, 예전 `walk_8.png`는 APK에서 제외했다.

- 모든 프레임은 걸음 중의 자세다. 앉기·정면 대기·출발 준비·마무리 자세를 넣지 않았다.
- 8프레임을 각각 120ms로 표시한다. 0.96초 주기이며 마지막 프레임의 추가 대기가 없다.
- 진행 중에는 반복하며 홈 재진입·백그라운드 복귀·완료 취소에서도 현재 상태에 맞춰 걷는다.
- 완료 전환의 축하는 한 번 재생하고 마지막 자세를 유지한다. 미룸·건너뜀·예정에서는 걷기를 멈춘다.
- 동작 줄이기 설정, 숨겨진 탭과 백그라운드에서는 움직임을 중단한다.
- 해달은 왼쪽을 향한 원본 걷기 셀을 재생 시 좌우 반전해 오른쪽을 향한다. 프레임 순서·속도와 대기·완료 방향은 그대로다.

## 최종 파일과 생성 프롬프트

| 캐릭터 | 앱용 시트 | 프롬프트 | 실제 홈 카드 미리보기 |
|---|---|---|---|
| 마법사 고양이 | [PNG](../../assets/characters/cat_stargazer/v1/motion/walk_loop_8.png) | [프롬프트](stargazer/IMAGEGEN_PROMPT.txt) | [GIF](../stargazer-events-8/walk/card-preview.gif) |
| 별빛 고양이 | [PNG](../../assets/characters/cat_starlight/v1/motion/walk_loop_8.png) | [프롬프트](starlight/IMAGEGEN_PROMPT.txt) | [GIF](../starlight-motion-8/walk/card-preview.gif) |
| 푸들 | [PNG](../../assets/characters/poodle_garden/v1/motion/walk_loop_8.png) | [프롬프트](poodle/IMAGEGEN_PROMPT.txt) | [GIF](../poodle-motion-8/walk/card-preview.gif) |
| 토끼 | [PNG](../../assets/characters/rabbit_postman/v1/motion/walk_loop_8.png) | [프롬프트](rabbit/IMAGEGEN_PROMPT.txt) | [GIF](../rabbit-motion-8/walk/card-preview.gif) |
| 다람쥐 | [PNG](../../assets/characters/squirrel_explorer/v1/motion/walk_loop_8.png) | [프롬프트](squirrel/IMAGEGEN_PROMPT.txt) | [GIF](../squirrel-motion-8/walk/card-preview.gif) |
| 달구름 양 | [PNG](../../assets/characters/sheep_mooncloud/v1/motion/walk_loop_8.png) | [프롬프트](sheep/IMAGEGEN_PROMPT.txt) | [GIF](../sheep-motion-8/walk/card-preview.gif) |
| 찻집 랫서팬더 | [PNG](../../assets/characters/redpanda_teashop/v1/motion/walk_loop_8.png) | [프롬프트](redpanda/IMAGEGEN_PROMPT.txt) | [GIF](../redpanda-motion-8/walk/card-preview.gif) |
| 햇살 해달 | [PNG](../../assets/characters/otter_seaside/v1/motion/walk_loop_8.png) | [프롬프트](otter/IMAGEGEN_PROMPT.txt) | [GIF](../otter-motion-8/walk/card-preview.gif) |
| 눈길 산책 펭귄 | [PNG](../../assets/characters/penguin_snow_walk/v1/motion/walk_loop_8.png) | [프롬프트](penguin/IMAGEGEN_PROMPT.txt) | [GIF](../penguin-motion-8/walk/card-preview.gif) |

각 캐릭터 폴더의 `source/generated-sheet.png`는 투명 배경으로 생성한 원본,
`frames/frame-01.png`부터 `frame-08.png`까지는 실제 앱 시트에 들어간 그림이다.
시트는 1536×768 RGBA이며 4열×2행, 셀은 384×384다.

`registration.json`은 원본의 접지선·배율·가로 중심이다. Swift 내보내기는 셀 분리,
최근접 축소와 위치 정렬만 수행한다. 한 시트 전체에 동일한 배율과 가로 기준을 사용하고
팔다리를 코드로 그리거나 중립 그림을 양 끝에 덮어쓰지 않는다.

## 검증

- 9종 반복 재생·상태 전환·홈 렌더링·이미지 회귀 검사를 포함해 104개 테스트 통과.
- 변경 Dart 20개 파일 정적 분석 및 Android debug APK 빌드 통과. 기존 데이터를 유지해 에뮬레이터 설치 완료.
- 72개 셀이 각각의 PNG와 정확히 일치하며, 잘림과 빈 셀이 없음을 확인했다.
- 각 걷기 시트의 8개 셀이 서로 다르고 대기 중립 그림과 중복되지 않음을 검사했다.
- 캐릭터별 3주기 재생, 재빌드 중 프레임 유지, 숨김/백그라운드 복귀 및 완료 전환을 검사했다.
- APK의 새 시트 9개가 작업 파일과 바이트 단위로 일치하고, 이전 걷기 시트 9개가 포함되지 않는 것을 확인했다.
- 시작·완료 시각 검증은 메모리 저장소로 실행한 실제 HomeScreen 렌더링을 사용한다. 사용자의 루틴 기록을 변경하지 않는다.

에뮬레이터에서 사용자가 선택한 별빛 고양이의 진행 중 화면을 약 8.3초 동안 4회 캡처해,
앉는 자세 없이 걷기 프레임이 계속 달라지는 것을 확인했다. [시간차 캡처](starlight/emulator-time-samples.png)
다른 8종의 시각 검증은 위의 실제 HomeScreen 렌더링으로 수행했다.
에뮬레이터 화면 녹화는 요청 시간보다 짧게 인코딩되어 연속 재생 검증에는 시간차 캡처를 사용했다.

## 재현

`flutter_app`에서:

```sh
swift -module-cache-path /private/tmp/loopet-swift-cache tool/export_home_walk_loops.swift
flutter test --no-pub test/home_walk_loop_assets_test.dart test/starlight_home_motion_test.dart tool/render_starlight_motion_preview.dart
swift -module-cache-path /private/tmp/loopet-swift-cache tool/encode_starlight_motion_previews.swift
```

다른 캐릭터는 해당 `render_*_motion_preview.dart`와 `encode_*_motion_previews.swift`를 사용한다.
마법사 고양이는 `render_stargazer_event_previews.dart`와 `encode_stargazer_event_previews.swift`다.
