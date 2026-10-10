# 유성 관측 고양이 출시 선물

현재 캐릭터 6포즈와 장식 3종은 384×384 투명 PNG로 앱에 포함되어 있다. 기본
`cat_starlight`와 광고 해금용 `poodle_garden`은 그대로 유지한다. 새로운
`cat_stargazer`는 첫 실행 날짜로 소유권을 판정하며, 받은 사용자는 이후에도
계속 선택할 수 있다.

## 출시 전 설정

`lib/domain/store/launch_gift.dart`의 `LaunchGiftCampaign.lastEligibleAt`을
확정된 종료 시각의 UTC `DateTime`으로 바꾼다. 현재 `null`이므로 지급은 꺼져
있다. 예를 들어 한국 시간 2026년 11월 30일 23:59:59까지라면
`DateTime.utc(2026, 11, 30, 14, 59, 59)`이다. 출시 날짜가 확정되기 전에는
스토어에 날짜나 무료 지급 문구를 게시하지 않는다.

첫 실행 시각은 앱 시작 시 기록한다. 이전 광고 워밍업 값
`ads.first_launch_at_ms`를 재사용하므로 기존 테스터 기록도 보존된다.
첫 실행이 종료 시각 이하이면 선물 팩을 소유하고, 홈에 처음 도착했을 때
선물 창을 한 번 본다. 창에서 즉시 입히거나 나중에 팩 목록에서 고를 수 있다.

로그인과 서버가 없으므로 기기를 바꾸거나 앱을 삭제한 뒤 다시 설치하면
첫 실행 기록과 선물 소유권은 복구되지 않는다. 기기 시계를 임의로 바꾸면
날짜 판정도 영향을 받는다.

## 스토어 문구 초안

날짜가 확정되고 지급이 켜진 빌드가 출시된 뒤 게시한다. 앱 이름과 아이콘에는
프로모션 문구를 넣지 않는다.

- ko: `[종료일]까지 LOOPET을 시작하면 한정 «유성 관측 고양이» 팩을 무료로 드려요.`
- en: `Start LOOPET by [end date] and get the limited Stargazer Cat pack for free.`
- es: `Empieza a usar LOOPET antes del [fecha] y recibe gratis el pack limitado Gato astrónomo.`
- ja: `[終了日]までにLOOPETを始めると、限定「星を見つめる猫」パックを無料で受け取れます。`
- pt: `Comece a usar o LOOPET até [data] e receba grátis o pacote limitado Gato Astrônomo.`

실제 표시 크기 시안은 `design/stargazer-source/app-size-preview.png`, 선물 화면
시안은 `design/stargazer-source/gift-preview.png`에 있다. 이미지 원본도 같은
폴더에 보존했다.
