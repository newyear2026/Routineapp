# 마법사 고양이 · 홈 대기 애니메이션 8프레임

2026-10-06. `cat_stargazer`의 홈 대기 포즈 테스트.

후속 작업으로 시작 걷기와 완료 축하를 연결했다. 현재 앱의 동작은
[시작·완료 모션 설명](../stargazer-events-8/README.md)을 참고한다.
이 폴더의 GIF는 첫 대기 모션 테스트 당시의 미리보기다.

- 동작: 눈 깜빡임 + 오른쪽 꼬리 살랑임. 발은 바닥에 고정.
- 8개 그림, 4초 반복. 프레임별 유지 시간(ms): 2800, 180, 100, 120, 100, 100, 180, 420.
- 앱 자산: `../../assets/characters/cat_stargazer/v1/motion/idle_8.png`.
  투명 PNG 1536×768, 4열 × 2행, 각 프레임 384×384. 위에서 아래, 왼쪽에서 오른쪽 순서.
- `frames/`: 각각의 투명 PNG 8장.
- `character-preview.gif`: 캐릭터 확대, 앱과 같은 타이밍.
- `card-preview.gif`, `home-preview.gif`: 실제 Flutter 홈 화면 렌더링, 앱과 같은 캐릭터 타이밍.
- 적용: `HomeFocusCard`에서 마법사 고양이가 `CatPose.idle`인 경우.
  다른 상태의 포즈는 기존 상태 매핑을 사용한다.
- 앱 비활성화, 숨겨진 탭, 동작 줄이기에서는 첫 프레임으로 정지.

## 원본과 생성

내장 ImageGen을 사용했다. 기준 그림은 기존
`assets/characters/cat_stargazer/v1/approved/idle.png`다.
정확한 생성 프롬프트는 `IMAGEGEN_PROMPT.txt`, 생성 결과는
`source/generated-sheet.png`에 보관한다.
Swift 내보내기 도구는 원본의 8개 셀을 분리하고 nearest-neighbor로 384px에
맞추는 작업만 수행한다. 눈과 꼬리를 코드로 새로 그리지 않는다.

## 재생성 및 검증

`flutter_app`에서:

```sh
swift -module-cache-path /private/tmp/loopet-swift-cache tool/export_stargazer_idle_atlas.swift
flutter test --no-pub tool/render_stargazer_idle_preview.dart
swift -module-cache-path /private/tmp/loopet-swift-cache tool/encode_stargazer_idle_preview.swift
flutter test --no-pub test/stargazer_home_motion_test.dart test/starlight_home_motion_test.dart test/home_screen_test.dart
```

미리보기에는 메모리 저장소와 고정 시각 2026-10-06 16:51을 사용한다.
실제 사용자 데이터는 수정하지 않는다. 실기기 설치 검증은 수행하지 않았다.
