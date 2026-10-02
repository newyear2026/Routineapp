# 햇살 해달 팩 원본

사용자가 고른 `raft-napper-v1.png`를 그대로 `rest-source.png`로 보존하고 휴식 포즈에 사용했다.
같은 해달의 둥근 얼굴, 분홍 볼, 갈색 발, 줄무늬 조개, 청록빛 물결을 기준으로
대기·활동·집중·완료·안내 포즈를 내장 imagegen 도구로 생성했다.

프롬프트 방향: 기존 팩과 같은 선명한 픽셀아트 화풍, 밝은 바닷가의 해달,
원본의 얼굴과 색을 유지, 투명한 배경과 잘리지 않는 전신.
`decorations-source.png`는 조개·물결·바다 유리,
`seaside-background-source.png`는 가로형 바다 풍경이다.

`python3 tool/prepare_otter_seaside_assets.py`로 앱에 싣는 384px 포즈와
128px 데코, 768×240 배경, Android·iOS 위젯 그림을 다시 준비한다.
