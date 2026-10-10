# 햇살 해달 · 홈 8프레임 모션

## 오른쪽 걷기 방향 보정 · 2026-10-07

`OtterHomeMotion`에서 걷기 셀만 좌우 반전해 오른쪽으로 걷도록 보정했다.
생성 원본과 8프레임 순서, 각 120ms의 반복 속도는 유지한다. 대기·완료에는 반전을 적용하지 않는다.
캐릭터·홈 카드 미리보기에도 같은 방향 보정을 적용한다.
9종 반복 재생 검사와 실제 홈 렌더링을 포함한 74개 테스트, 변경 Dart 2개 파일 정적 분석이 통과했다.
걷기 미리보기만 다시 인코딩할 때는 `tool/encode_otter_motion_previews.swift --walk-only`를 사용한다.

## 멈춤 자세 제거 · 2026-10-07

걷기 시트를 반복 전용 8프레임으로 다시 제작했다. 첫·마지막 프레임에 앉은 대기 그림을
넣지 않으며, 모든 프레임을 120ms로 표시해 0.96초마다 연결한다. 기존 시트·생성 기록은
보관용이며 앱에서는 `walk_loop_8.png`를 사용한다.
[새 걷기 원본·프롬프트·검증](../home-walk-loop-8/README.md) · [이 캐릭터 프롬프트](../home-walk-loop-8/otter/IMAGEGEN_PROMPT.txt)

## 집중 시간 반복 재생 · 2026-10-07

진행 중에는 걷기 8프레임을 계속 반복한다. 예정/미룸/건너뜀으로 바뀌면 걷기를 멈추고,
완료 전환에서는 축하를 한 번 재생한 뒤 마지막 자세를 유지한다. 진행 중 화면 재진입,
완료 취소 및 백그라운드/탭 복귀 시에는 현재 상태에 맞춰 걷기를 재개한다.
동작 줄이기 설정에서는 걷지 않는다. 이전 원본은 보존했으며, 현재 걷기는 별도의 반복 전용 시트를 사용한다.
9종 반복 재생·상태 전환·실제 홈 렌더링을 포함한 94개 테스트와 변경 Dart 19개 파일의
정적 분석이 통과했다. Android debug 빌드도 성공했다.

2026-10-07. 내장 ImageGen으로 기존 해달의 황금빛 갈색 털, 크림색 배, 수염과 분홍 조개를 유지해 제작했다.
대기·루틴 시작·완료 각각 8프레임이며 홈 화면의 `OtterHomeMotion`으로 연결했다.

| 모션 | 동작 | 앱 동작 | 미리보기 |
|---|---|---|---|
| 대기 | 조개를 안고 눈을 깜빡이며 꼬리를 살짝 흔들기 | 4초 반복 | [캐릭터](idle/character-preview.gif) · [홈 카드](idle/card-preview.gif) |
| 시작 | 조개를 두 앞발로 안고 일어나 짧게 뒤뚱걷기 | 진행 중 0.96초 주기로 반복 | [캐릭터](walk/character-preview.gif) · [홈 카드](walk/card-preview.gif) |
| 완료 | 조개를 턱 아래로 들어 보여주며 눈을 감고 웃기 | 약 1초 뒤 마지막 자세 유지 | [캐릭터](complete/character-preview.gif) · [홈 카드](complete/card-preview.gif) |

걷기 GIF는 앱과 같은 속도로 반복한다. 완료 GIF에만 검수용 2초 대기와 반복을 적용한다. 실제 앱의 완료 모션은 한 번 재생한다.

## 최종 파일 및 프롬프트

| 모션 | 앱용 시트 | 최종 생성 프롬프트 |
|---|---|---|
| 대기 | [idle_8.png](../../assets/characters/otter_seaside/v1/motion/idle_8.png) | [프롬프트](idle/IMAGEGEN_PROMPT.txt) |
| 시작 | [walk_8.png](../../assets/characters/otter_seaside/v1/motion/walk_loop_8.png) | [프롬프트](walk/IMAGEGEN_PROMPT.txt) |
| 완료 | [complete_8.png](../../assets/characters/otter_seaside/v1/motion/complete_8.png) | [프롬프트](complete/IMAGEGEN_PROMPT.txt) |

시트는 1536×768 RGBA, 4열×2행이며 셀은 384×384다. 각 모션의 `source/generated-sheet.png`에 생성 원본을 보존했다.
`frames/`는 개별 PNG, `rendered/`는 메모리 데이터로 실행한 실제 HomeScreen의 캡처다.
Swift 내보내기는 셀 분리, 최근접 균일 크기 보정과 바닥 정렬만 수행하며 그림이나 팔다리를 새로 그리지 않는다.
시트별 첫 중립 자세의 높이로 모션 간 크기를 맞추고, 한 모션의 모든 그림에는 동일한 배율을 적용했다.
모든 모션의 첫 그림과 대기·걷기의 마지막 그림은 동일한 중립 프레임이다. 앉은 완료 동작은 뒷발의 접지선을 유지한다.

## 동작 및 검증

- 기존 `HomeCharacterMotion` 재생기를 사용하며 예정/미룸 → 진행 중 또는 새 루틴 시작에 걷기를 재생한다.
- 같은 루틴의 진행 중/미룸 → 완료에 축하를 재생한다. 완료 상태로 화면에 진입하면 마지막 자세를 표시한다.
- 동작 줄이기, 숨겨진 화면, 백그라운드 상태를 존중하며 이전 이벤트를 뒤늦게 재생하지 않는다.
- 해달·펭귄과 기존 7종, 홈 상태 전환 및 HomeScreen 렌더링을 포함한 87개 테스트 통과.
- 변경/추가한 Dart 7개 파일의 정적 분석 통과. Android debug APK 빌드 성공.
- 두 캐릭터 48개 셀의 투명 여백, 잘림, 개별 PNG와 시트 일치, 중립 연결 프레임 일치 확인.
- 실제 HomeScreen 렌더링으로 걷기·완료의 모든 프레임을 검수했다. 팔다리 중복 없이 카드 안에 표시된다.
- APK의 9종 모션 시트 27개가 작업 파일과 바이트 단위로 일치한다.
- 연결된 Android 에뮬레이터에 기존 데이터를 유지해 새 APK를 설치했다.

해달의 상태별 동작 검증은 메모리 저장소를 사용하는 HomeScreen 테스트에서 수행했다.
사용자의 실제 루틴을 완료하지 않았으며 실물 휴대폰 검증은 수행하지 않았다.

## 재현

`flutter_app` 디렉터리에서:

```sh
swift -module-cache-path /private/tmp/loopet-swift-cache tool/export_otter_motion_atlases.swift
flutter test --no-pub test/otter_home_motion_test.dart tool/render_otter_motion_preview.dart
swift -module-cache-path /private/tmp/loopet-swift-cache tool/encode_otter_motion_previews.swift
```
