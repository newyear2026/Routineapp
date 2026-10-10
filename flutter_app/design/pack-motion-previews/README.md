# 캐릭터 팩 움직임 시안

실제 Flutter `HomeScreen`의 상단과 카드 영역을 캡처한 GIF입니다.
한 팩에 아침·낮·노을·밤을 2×2로 배치했습니다. 200ms 간격 30프레임,
6초 반복이며 GIF에서는 실제 앱보다 프레임 수가 적습니다.
배경 원화는 고정이고 작은 효과와 기존 캐릭터 동작만 움직입니다.
고정 팔레트를 사용하여 GIF 색 양자화로 생기는 배경 깜빡임을 줄였습니다.

재생성:
```
flutter test --no-pub tool/render_pack_time_scenes.dart \
  --dart-define=PREVIEW_FONT=/System/Library/Fonts/Supplemental/AppleGothic.ttf \
  --dart-define=RENDER_MOTION=true \
  --dart-define=AUDIT_OUTPUT_DIR=/private/tmp/loopet-motion-frames
python3 tool/build_pack_motion_boards.py
```
