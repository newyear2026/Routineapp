# 마법사 고양이 · 시작 걷기 / 완료 축하

## 멈춤 자세 제거 · 2026-10-07

걷기 시트를 반복 전용 8프레임으로 다시 제작했다. 첫·마지막 프레임에 앉은 대기 그림을
넣지 않으며, 모든 프레임을 120ms로 표시해 0.96초마다 연결한다. 기존 시트·생성 기록은
보관용이며 앱에서는 `walk_loop_8.png`를 사용한다.
[새 걷기 원본·프롬프트·검증](../home-walk-loop-8/README.md) · [이 캐릭터 프롬프트](../home-walk-loop-8/stargazer/IMAGEGEN_PROMPT.txt)

## 집중 시간 반복 재생 · 2026-10-07

진행 중에는 걷기 8프레임을 계속 반복한다. 예정/미룸/건너뜀으로 바뀌면 걷기를 멈추고,
완료 전환에서는 축하를 한 번 재생한 뒤 마지막 자세를 유지한다. 진행 중 화면 재진입,
완료 취소 및 백그라운드/탭 복귀 시에는 현재 상태에 맞춰 걷기를 재개한다.
동작 줄이기 설정에서는 걷지 않는다. 이전 원본은 보존했으며, 현재 걷기는 별도의 반복 전용 시트를 사용한다.
9종 반복 재생·상태 전환·실제 홈 렌더링을 포함한 94개 테스트와 변경 Dart 19개 파일의
정적 분석이 통과했다. Android debug 빌드도 성공했다.

2026-10-06. 기존 8프레임 대기에 연결한 두 가지 8프레임 모션.

| 모션 | 내용 | 앱 재생 |
|---|---|---|
| 시작 | 살짝 돌아서 제자리 두 걸음 → 앉기 | 진행 중 0.96초 주기로 반복 |
| 완료 | 웅크리기 → 작은 점프와 별 2개 → 착지 → 웃기 | 1.2초 한 번, 마지막 웃는 프레임 유지 |

## 미리보기와 자산

- [시작 캐릭터 GIF](walk/character-preview.gif) · [실제 홈 카드 GIF](walk/card-preview.gif)
- [완료 캐릭터 GIF](complete/character-preview.gif) · [실제 홈 카드 GIF](complete/card-preview.gif)
- [걷기 PNG 시트](../../assets/characters/cat_stargazer/v1/motion/walk_loop_8.png)
- [완료 PNG 시트](../../assets/characters/cat_stargazer/v1/motion/complete_8.png)

PNG는 각각 1536×768 투명 이미지이며, 4열 × 2행의 384×384 프레임 8개다.
왼쪽에서 오른쪽, 위에서 아래 순서로 읽는다. 개별 PNG는 각 모션의 `frames/`에 있다.
걷기 GIF는 앱과 같은 속도로 반복한다. 완료 GIF에만 검수용 2초 대기와 반복을 적용한다. 앱에서는 완료 모션을 한 번 재생한다.

## 트리거와 표시

- 홈을 보고 있을 때 예정 → 진행 중, 미룸 → 진행 중, 새로운 루틴 시작에서 걷기를 재생한다.
- 같은 루틴의 진행 중/미룸 → 완료 전환에서 축하를 재생한다.
- 이미 진행 중인 루틴으로 홈을 처음 열어도 걷기 모션을 반복한다.
- 이미 완료된 루틴이나 하루 종료 화면으로 진입하면 웃는 마지막 프레임을 보여준다.
- 단순 상태 갱신은 걷기 프레임을 초기화하지 않는다. 완료 취소와 활성 화면 재진입은 걷기를 재개한다.
- 배경 전환, 숨겨진 탭, 동작 줄이기는 이벤트 재생을 중단한다. 복귀 때 이벤트를 뒤늦게 재생하지 않는다.
- 루틴은 로케일에 독립적인 날짜와 ID로 구분한다.
- 88×96 홈 캐릭터 영역에서 모든 시트를 같은 배율과 바닥선으로 표시한다.
  각 셀을 별도로 클리핑해 위쪽 셀의 발이 다음 셀의 빈 공간에 보이지 않게 했다.

## 생성과 정렬

### 완료 모션 6번 프레임 해부학 수정

초기 착지 그림에는 가슴 높이에 든 앞발 2개 외에 바닥의 발이 4개 더 그려져,
총 6개로 보이는 오류가 있었다. 내장 ImageGen으로 바닥 양옆의 작은 중복 발
2개를 제거해 앞발 2개와 뒷발 2개로 수정했다.

- [수정 프롬프트](complete/REPAIR_PROMPT.txt)
- 수정 원본: `complete/source/repaired-frame-06.png`
- 잘못된 원본 기록: `complete/source/rejected-frame-06-six-paws.png` (앱에서 사용하지 않음)
- 내보내기 도구는 6번 프레임에만 수정본을 사용하고 기존 바닥선과 크기에 정렬한다.
- 완료 모션 나머지 7프레임, 걷기 8프레임은 변경하지 않았다.

그림의 팔다리 수는 이미지 검수로 확인했다. 재생 코드 테스트만으로 이와 같은
그림의 해부학적 오류를 검증할 수는 없다.

내장 ImageGen으로 각각 제작했다. 기존 대기 1번 프레임을 캐릭터 정체성의 기준으로,
기존 활동/완료 원화를 보조 포즈 기준으로 사용했다.

- [걷기 생성 프롬프트](walk/IMAGEGEN_PROMPT.txt)
- [완료 생성 프롬프트](complete/IMAGEGEN_PROMPT.txt)
- 각 폴더의 `source/generated-sheet.png`: ImageGen 원본

Swift 도구는 셀 분리, nearest-neighbor 축소, 발바닥 위치 정렬만 수행한다.
걷기는 모든 프레임의 발을 같은 바닥선에 맞추고, 완료는 점프의 높이 차를 유지한다.
첫 프레임과 걷기의 마지막 프레임은 기존 대기의 첫 프레임을 그대로 사용해 연결한다.
캐릭터나 효과를 코드로 새로 그리지 않았다.

## 재현 및 검증

`flutter_app`에서:

```sh
swift -module-cache-path /private/tmp/loopet-swift-cache tool/export_stargazer_event_atlases.swift
flutter test --no-pub tool/render_stargazer_event_previews.dart
swift -module-cache-path /private/tmp/loopet-swift-cache tool/encode_stargazer_event_previews.swift
flutter test --no-pub test/stargazer_home_motion_test.dart test/starlight_home_motion_test.dart test/home_screen_test.dart test/home_cat_pose_test.dart
```

미리보기 도구는 메모리 저장소에서 실제 HomeScreen을 띄우고, 17:59 → 18:00으로
시각을 바꾼 후 컨트롤러의 완료 액션을 실행해 전체 경로를 렌더링한다.
실제 사용자 데이터나 설치된 앱은 변경하지 않는다. 실기기 검증은 수행하지 않았다.
