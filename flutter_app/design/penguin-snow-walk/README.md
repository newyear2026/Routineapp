# 눈꽃 산책 펭귄 팩 원본

`idle-source.png`는 사용자가 고른 펭귄 시안의 원본이다. 이 그림의 얼굴,
보랏빛 목도리, 주황색 부리와 발을 기준으로 내장 imagegen 도구를 사용해
`pose-sheet-source.png`(활동·집중·완료·휴식·안내)를 만들었다.
`decorations-source.png`는 눈꽃·벙어리장갑·보온병이며,
`header-source.png`와 `card-source.png`는 각각 다른 구도의 겨울 풍경이다.

프롬프트 방향: 기존 캐릭터팩의 선명한 픽셀아트 화풍, 같은 어린 펭귄의
여섯 동작, 눈길과 목도리, 투명한 캐릭터·장식 배경, 글자가 놓일 왼쪽을
밝게 비운 겨울 풍경.

`python3 tool/prepare_penguin_snow_walk_assets.py`를 실행하면 384px 포즈,
128px 장식, 시간대 장면 두 장, 앱·Android·iOS 위젯 그림을 준비한다.
