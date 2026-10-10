# 랫서팬더 찻집 팩 원본

`pose-sheet-v1.png`에서 정한 얼굴 무늬, 줄무늬 꼬리, 청록색 앞치마를 기준으로
`idle-source.png`와 나머지 다섯 포즈를 각각 생성했다. `decorations-source.png`는
찻주전자·비 오는 창·찻잔, `teashop-background-source.png`는 홈과 위젯의
가로형 찻집 풍경이다. 이미지는 내장 imagegen 도구로 만들었다.

프롬프트 방향: 기존 팩과 같은 선명한 픽셀아트 화풍의 랫서팬더 바리스타,
비 오는 날의 찻집, 녹청색 앞치마, 여섯 포즈(대기·활동·집중·완료·휴식·안내),
투명한 배경과 잘리지 않는 전신.

`python3 tool/prepare_redpanda_teashop_assets.py`로 앱에 싣는 384px 포즈와
128px 데코, 768×240 찻집 배경, Android·iOS 위젯 그림을 다시 준비한다.
