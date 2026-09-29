# 고양이 별빛 대표 자세 v1
Built-in image_gen으로 제작한 투명 RGBA PNG 6종. 앱 적용 대상으로 검수한 파일은 `approved/`에 정리했다. 생성 프롬프트: prompts.json.
idle: 대기 / activity: 활동 / focus: 집중 / complete: 완료 / rest: 휴식 / guide: 안내.
모든 원본 1254×1254, 알파 최솟값 0 및 최댓값 255 확인.
focus/rest/guide의 최초 체크무늬 배경은 image_gen으로 제거 후 검증.

## 배치와 한계
남색 털, 크림색 무늬, 호박색 눈, 청록 목걸이와 금색 버클을 공통 기준으로 제작했다.
대표 자세이므로 픽셀 단위로 동일한 팔레트/얼굴의 연속 애니메이션 프레임은 아니다.
원본의 실제 바닥 위치는 서로 다르다. placement.json의 scale을 원본 좌표에 곱한 뒤 translate를 더하면 불투명 경계 바닥이 모두 y=1080에 놓인다.
앱 표시 크기로 변환할 때 displaySize/1254를 곱한다.
scale은 시각적 크기를 근접하게 맞춘 초기값이다. preview.html에서 확인 가능하다.
PNG에 정렬 변환을 구워 넣지는 않았다. 이미지 자체를 같은 바닥선으로 재출력하는 작업과 연속 프레임 제작은 후속 작업이다.
`guide-corrected.png`를 최종 안내 자세로 채택해 `approved/guide.png`로 복사했다.
사용자가 선택한 상반신 응원 이미지를 최종 완료 자세로 채택해 `complete.png`와 `approved/complete.png`에 반영했다. 이전 전신형은 `complete-full-body.png`로 보관했다.
`cheer-star-preview.png`는 별을 안은 추가 응원 자세 시안이며 배경이 포함되어 대표 투명 PNG 6종에서는 제외했다.
앱의 기존 캐릭터/화면은 변경하지 않았다. assets 등록 및 공통 캐릭터 위젯 연결은 다음 단계다.
