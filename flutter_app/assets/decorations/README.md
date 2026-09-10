# 픽셀 장식 이미지

2026-09-08 imagegen으로 제작한 투명 PNG: plant, sleeping-cat, bell.
앱의 정적인 장식으로만 사용하며 루틴 종류·완료 상태·캐릭터 선택을 의미하지 않는다.

- `PixelDecoration`: 종횡비 유지, 픽셀 필터, 디코딩 폭 256, 터치·시맨틱 제외
- `DecoratedTimetable`: 시간표 모서리의 여백에만 배치
- 구름·반짝임은 같은 위젯 파일의 간단한 픽셀 도형으로 렌더링
- `tool/render_pixel_home.dart`: 이미지 디코딩을 기다린 뒤 실제 화면 캡처
