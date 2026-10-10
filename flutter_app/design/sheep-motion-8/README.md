# 달구름 양 · 홈 8프레임 모션

## 멈춤 자세 제거 · 2026-10-07

걷기 시트를 반복 전용 8프레임으로 다시 제작했다. 첫·마지막 프레임에 앉은 대기 그림을
넣지 않으며, 모든 프레임을 120ms로 표시해 0.96초마다 연결한다. 기존 시트·생성 기록은
보관용이며 앱에서는 `walk_loop_8.png`를 사용한다.
[새 걷기 원본·프롬프트·검증](../home-walk-loop-8/README.md) · [이 캐릭터 프롬프트](../home-walk-loop-8/sheep/IMAGEGEN_PROMPT.txt)

## 집중 시간 반복 재생 · 2026-10-07

진행 중에는 걷기 8프레임을 계속 반복한다. 예정/미룸/건너뜀으로 바뀌면 걷기를 멈추고,
완료 전환에서는 축하를 한 번 재생한 뒤 마지막 자세를 유지한다. 진행 중 화면 재진입,
완료 취소 및 백그라운드/탭 복귀 시에는 현재 상태에 맞춰 걷기를 재개한다.
동작 줄이기 설정에서는 걷지 않는다. 이전 원본은 보존했으며, 현재 걷기는 별도의 반복 전용 시트를 사용한다.
9종 반복 재생·상태 전환·실제 홈 렌더링을 포함한 94개 테스트와 변경 Dart 19개 파일의
정적 분석이 통과했다. Android debug 빌드도 성공했다.

2026-10-07. 내장 ImageGen으로 기존 캐릭터의 크림색 구름 털과 연보라 음영, 작은 뿔, 별빛 눈, 보라색 발굽과 달 목걸이를 유지해 제작했다.
대기·루틴 시작·완료 각각 8프레임이며 홈 화면의 `SheepHomeMotion`으로 연결했다.

| 모션 | 동작 | 앱 동작 | 미리보기 |
|---|---|---|---|
| 대기 | 느린 눈 깜빡임과 귀 까딱임 | 4초 반복 | [캐릭터](idle/character-preview.gif) · [홈 카드](idle/card-preview.gif) |
| 시작 | 가볍게 네 발로 걷고 원래 앉은 자세로 복귀 | 진행 중 0.96초 주기로 반복 | [캐릭터](walk/character-preview.gif) · [홈 카드](walk/card-preview.gif) |
| 완료 | 작은 점프와 부드러운 착지 후 활짝 웃기 | 약 1초 뒤 마지막 자세 유지 | [캐릭터](complete/character-preview.gif) · [홈 카드](complete/card-preview.gif) |

걷기 GIF는 앱과 같은 속도로 반복한다. 완료 GIF에만 검수용 2초 대기와 반복을 적용했다.
앱에서는 진행 중에 걷기를 반복하고, 완료 전환의 축하는 한 번 재생한 뒤 마지막 자세를 유지한다.

## 최종 파일 및 프롬프트

| 모션 | 앱용 시트 | 최종 생성 프롬프트 |
|---|---|---|
| 대기 | [idle_8.png](../../assets/characters/sheep_mooncloud/v1/motion/idle_8.png) | [프롬프트](idle/IMAGEGEN_PROMPT.txt) |
| 시작 | [walk_8.png](../../assets/characters/sheep_mooncloud/v1/motion/walk_loop_8.png) | [프롬프트](walk/IMAGEGEN_PROMPT.txt) |
| 완료 | [complete_8.png](../../assets/characters/sheep_mooncloud/v1/motion/complete_8.png) | [프롬프트](complete/IMAGEGEN_PROMPT.txt) |

각 시트는 1536×768 RGBA, 4열×2행이며 셀 하나는 384×384다.
각 모션의 `source/generated-sheet.png`에 내장 ImageGen 생성 원본을 보존했다.
`frames/`는 개별 PNG, `rendered/`는 메모리 데이터로 실행한 실제 HomeScreen의 캡처다.

Swift 내보내기 도구는 셀 분리, 최근접 균일 크기 보정과 바닥 정렬을 수행한다.
시트별 첫 중립 자세의 높이를 기준으로 모션 간 크기를 맞췄으며,
각 모션의 8개 그림에는 동일한 배율을 적용한다. 개별 프레임을 매번 자동 확대하지 않는다.
양의 완료 3–5프레임은 원본 시트의 공중 높이를 보존한다.
모든 모션의 첫 그림과 대기·걷기의 마지막 그림은 동일한 중립 프레임을 사용한다.
그림이나 팔다리를 코드로 새로 그리지 않았다. 팔다리 중복, 투명도, 누락 및 잘림을 검수했다.

## 앱 동작 및 검증

- 기존 공통 `HomeCharacterMotion` 재생기를 사용한다.
- 예정/미룸 → 진행 중, 또는 새 루틴 시작에서 걷기를 재생한다.
- 같은 루틴의 진행 중/미룸 → 완료에서 축하를 재생한다.
- 이미 진행 중인 화면에 진입하면 걷기를 반복하고, 이미 완료된 화면은 마지막 축하 자세를 표시한다.
- 동작 줄이기, 숨겨진 화면, 백그라운드에서 중단하고 이벤트를 뒤늦게 재생하지 않는다.
- 휴식·안내 상태 및 팩의 기존 배경은 유지한다.

양·랫서팬더와 기존 다섯 캐릭터, 홈 상태 전환, 실제 홈 렌더링을 포함해 73개 테스트 통과.
이번에 변경/추가한 Dart 7개 파일의 정적 분석 통과. Android debug APK 빌드 성공.
APK 안의 7종 캐릭터 모션 시트 21개가 작업 파일과 정확히 일치함을 확인했다.
새 APK를 연결된 Android 에뮬레이터에 기존 데이터를 유지해 설치했다.
양·랫서팬더의 상태별 재생과 시각 검증은 메모리 저장소를 사용하는 HomeScreen 테스트로
수행했다. 사용자의 루틴을 테스트용으로 완료하지 않았으며, 두 팩을 에뮬레이터에서
직접 선택해 재생하는 검증이나 실물 휴대폰 검증은 수행하지 않았다.

## 재현

`flutter_app` 디렉터리에서:

```sh
swift -module-cache-path /private/tmp/loopet-swift-cache tool/export_sheep_motion_atlases.swift
flutter test --no-pub test/sheep_home_motion_test.dart tool/render_sheep_motion_preview.dart
swift -module-cache-path /private/tmp/loopet-swift-cache tool/encode_sheep_motion_previews.swift
```
