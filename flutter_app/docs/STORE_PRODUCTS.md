# 인앱 상품

LOOPET이 Google Play에서 파는 상품과 Play Console에서 할 일. 코드의 기준은
`lib/data/store/store_product_catalog.dart`와 `lib/data/store/character_pack_catalog.dart`다.

## Play Console에 등록할 상품

모두 **비소모성**(관리형 상품)이다. 코드의 ID와 한 글자라도 다르면 가격이 뜨지 않고
살 수 없다. **상품 ID는 한 번 만들면 지워도 다시 쓸 수 없으므로** 바꾸지 않는다.

| 상품 ID | 지급 | 멕시코 가격 | 기본 가격 |
| --- | --- | --- | --- |
| `loopet.pack.rabbit_postman` | 우편배달부 토끼 팩 | MX$39 | US$1.99 등급 |
| `loopet.pack.squirrel_explorer` | 탐험가 다람쥐 팩 | MX$39 | US$1.99 등급 |
| `loopet.pack.sheep_mooncloud` | 달구름 양 팩 | MX$39 | US$1.99 등급 |
| `loopet.pack.redpanda_teashop` | 랫서팬더 찻집 팩 | MX$39 | US$1.99 등급 |
| `loopet.pack.otter_seaside` | 햇살 해달 팩 | MX$39 | US$1.99 등급 |
| `loopet.supporter.bundle` | 토끼·다람쥐·양·랫서팬더·해달 5종 + 광고 제거 | MX$89 | US$4.99 등급 |

- 가격은 결제 프로필 통화로 기본 가격을 한 번 정하고, 멕시코만 MX$39·MX$89로 덮어쓴다.
  Sobrita의 캐릭터(MX$39)·번들(MX$89)과 같은 등급이다.
- 번들은 `StoreProductCatalog.bundlePackIds`의 다섯 팩으로 구성을 고정한다.
  새 판매 팩을 추가해도 이 상품의 구성은 늘어나지 않는다.
- 푸들 정원과 눈꽃 산책 펭귄은 이 묶음에서 제외하고, 각각 보상형 광고 2회로 연다.
  광고로 연 권리는 묶음 구매·복원·환불과 별개로 유지된다.
  현재 광고를 지원하지 않는 iOS에서는 두 팩을 바로 선택할 수 있다.
- 출시 선물(유성 관측 고양이)은 어떤 상품에도 넣지 않는다. 기간 안에 시작한 사람만
  갖는 것이 선물의 뜻이다.
- 광고 제거(`ads.removed`)는 홈·진행 화면의 네이티브 광고만 끈다. 보상형 광고는 사용자가
  눌러야 시작하므로 남긴다.

## Play Console 이름·설명

Google Play 구매 창에 보이는 글이다. 이름은 55자, 설명은 200자까지다. 이름은 앱의
`pack…Name`, 설명 첫 문장은 `pack…Tagline`과 같게 맞췄다. 팩 설명은 같은 틀
(소개 → 캐릭터 → 색 테마 → 장식 3종 → 위젯)을 따른다.

### `loopet.pack.rabbit_postman`

| 언어 | 이름 | 설명 |
| --- | --- | --- |
| ko | 우편배달부 토끼 팩 | 작은 편지와 함께 시작하는 따뜻한 아침. 루틴에 맞춰 움직이는 우편배달부 토끼, 전용 색 테마, 편지·가방·당근 우표 장식, 어울리는 홈 화면 위젯이 들어 있어요. |
| en | Postman Rabbit Pack | A warm morning with a little letter. Includes the Postman Rabbit, who moves with your routines, its own color theme, letter, satchel and carrot stamp decor, and a matching home widget. |
| es | Pack Conejo Cartero | Una mañana cálida con una pequeña carta. Incluye al Conejo Cartero, que se mueve con tus rutinas, su propio tema de color, adornos de carta, bolso y sello, y un widget a juego. |
| ja | 郵便配達うさぎパック | 小さな手紙と始めるあたたかな朝。ルーティンに合わせて動く郵便配達うさぎ、専用カラーテーマ、手紙・かばん・にんじん切手の飾り、おそろいのホーム画面ウィジェットが入っています。 |
| pt | Pacote Coelho Carteiro | Uma manhã acolhedora com uma cartinha. Inclui o Coelho Carteiro, que se mexe com suas rotinas, um tema de cores próprio, enfeites de carta, bolsa e selo, e um widget combinando. |

### `loopet.pack.squirrel_explorer`

| 언어 | 이름 | 설명 |
| --- | --- | --- |
| ko | 탐험가 다람쥐 팩 | 도토리 모자를 쓰고 오늘의 길을 찾아요. 루틴에 맞춰 움직이는 탐험가 다람쥐, 전용 색 테마, 도토리·지도·배낭 장식, 어울리는 홈 화면 위젯이 들어 있어요. |
| en | Explorer Squirrel Pack | Find today's path with a little woodland explorer. Includes the Explorer Squirrel, who moves with your routines, its own color theme, acorn, map and backpack decor, and a matching home widget. |
| es | Pack Ardilla Exploradora | Descubre el camino de hoy con una pequeña exploradora. Incluye a la Ardilla, que se mueve con tus rutinas, su tema de color, adornos de bellota, mapa y mochila, y un widget a juego. |
| ja | 探検家リスパック | どんぐり帽子で今日の道を見つけよう。ルーティンに合わせて動く探検家リス、専用カラーテーマ、どんぐり・地図・リュックの飾り、おそろいのホーム画面ウィジェットが入っています。 |
| pt | Pacote Esquilo Explorador | Encontre o caminho de hoje com um pequeno explorador. Inclui o Esquilo, que se mexe com suas rotinas, um tema de cores próprio, enfeites de bolota, mapa e mochila, e um widget combinando. |

### `loopet.pack.sheep_mooncloud`

| 언어 | 이름 | 설명 |
| --- | --- | --- |
| ko | 달구름 양 팩 | 달빛 구름 위에서 포근한 하루를 보내요. 루틴에 맞춰 움직이는 달구름 양, 전용 색 테마, 구름·달·책 장식, 어울리는 홈 화면 위젯이 들어 있어요. |
| en | Mooncloud Sheep Pack | A gentle day among moonlit clouds. Includes the Mooncloud Sheep, who moves with your routines, its own color theme, cloud, moon and book decor, and a matching home widget. |
| es | Pack Ovejita de Luna y Nubes | Un día apacible entre nubes iluminadas por la luna. Incluye a la Ovejita, que se mueve con tus rutinas, su tema de color, adornos de nube, luna y libro, y un widget a juego. |
| ja | 月雲ひつじパック | 月明かりの雲と一緒に、穏やかな一日を。ルーティンに合わせて動く月雲ひつじ、専用カラーテーマ、雲・月・本の飾り、おそろいのホーム画面ウィジェットが入っています。 |
| pt | Pacote Ovelhinha da Lua e das Nuvens | Um dia tranquilo entre nuvens iluminadas pela lua. Inclui a Ovelhinha, que se mexe com suas rotinas, um tema de cores próprio, enfeites de nuvem, lua e livro, e um widget combinando. |

### `loopet.pack.redpanda_teashop`

| 언어 | 이름 | 설명 |
| --- | --- | --- |
| ko | 랫서팬더 찻집 팩 | 비 오는 날, 랫서팬더와 따뜻한 차 한 잔. 루틴에 맞춰 움직이는 랫서팬더, 전용 색 테마, 찻주전자·창문·찻잔 장식, 어울리는 홈 화면 위젯이 들어 있어요. |
| en | Red Panda Teashop Pack | A warm cup of tea on a rainy day. Includes the Red Panda, who moves with your routines, its own color theme, teapot, window and teacup decor, and a matching home widget. |
| es | Pack Panda Rojo de la Tetería | Una taza de té caliente para un día de lluvia. Incluye al Panda Rojo, que se mueve con tus rutinas, su tema de color, adornos de tetera, ventana y taza, y un widget a juego. |
| ja | レッサーパンダの喫茶店パック | 雨の日は温かいお茶でひと休み。ルーティンに合わせて動くレッサーパンダ、専用カラーテーマ、ティーポット・窓・ティーカップの飾り、おそろいのホーム画面ウィジェットが入っています。 |
| pt | Pacote Casa de Chá do Panda-Vermelho | Uma xícara de chá quentinho em um dia chuvoso. Inclui o Panda-Vermelho, que se mexe com suas rotinas, um tema de cores próprio, enfeites de bule, janela e xícara, e um widget combinando. |

### `loopet.pack.otter_seaside`

| 언어 | 이름 | 설명 |
| --- | --- | --- |
| ko | 햇살 해달 팩 | 조개를 품고 물결 위에서 느긋한 하루. 루틴에 맞춰 움직이는 햇살 해달, 전용 색 테마, 조개·물결·바다 유리 장식, 어울리는 홈 화면 위젯이 들어 있어요. |
| en | Sunny Sea Otter Pack | Drift through a gentle day with a little seashell. Includes the Sea Otter, who moves with your routines, its own color theme, shell, wave and sea glass decor, and a matching home widget. |
| es | Pack Nutria Marina Soleada | Un día tranquilo entre olas y conchas. Incluye a la Nutria Marina, que se mueve con tus rutinas, su propio tema de color, adornos de concha, ola y vidrio marino, y un widget a juego. |
| ja | ひだまりラッコパック | 貝殻を抱いて、波の上でのんびり。ルーティンに合わせて動くひだまりラッコ、専用カラーテーマ、貝殻・波・シーグラスの飾り、おそろいのホーム画面ウィジェットが入っています。 |
| pt | Pacote Lontra Marinha Ensolarada | Um dia tranquilo entre ondas e conchas. Inclui a Lontra Marinha, que se mexe com suas rotinas, um tema de cores próprio, enfeites de concha, onda e vidro do mar, e um widget combinando. |

### `loopet.supporter.bundle` (5종 + 광고 제거 — 내용 고정)

기존 상품 ID를 유지하고 구성·이름·설명을 5종으로 맞춘다. 앱의 표시와 지급 구성은
수정되어 있으며, Play Console 구매 창의 상품 이름·설명은 아래 값으로 별도 저장해야 한다.
가격은 이번 구성 변경에서 바꾸지 않는다.

| 언어 | 이름 | 설명 |
| --- | --- | --- |
| ko | 5종 캐릭터팩 + 광고 제거 | 우편배달부 토끼, 탐험가 다람쥐, 달구름 양, 랫서팬더 찻집, 햇살 해달 팩을 한 번에 열어요. 각 팩의 캐릭터·테마·장식·위젯과 홈·진행 화면 광고 제거가 포함돼요. |
| en | 5 Character Packs + No Ads | Unlock Postman Rabbit, Explorer Squirrel, Mooncloud Sheep, Red Panda Teashop and Sunny Sea Otter, with their themes, decor and widgets. Removes ads on Home and Progress. |
| es | 5 packs de personaje + sin anuncios | Incluye Conejo Cartero, Ardilla Exploradora, Ovejita, Panda Rojo y Nutria Marina, con sus temas, adornos y widgets. Quita los anuncios de Inicio y Progreso. |
| ja | キャラクターパック5種＋広告なし | 郵便配達うさぎ、探検家リス、月雲ひつじ、レッサーパンダの喫茶店、ひだまりラッコの5パックをまとめて。各パックのテーマ・飾り・ウィジェットが含まれ、ホームと進捗画面の広告もなくします。 |
| pt | 5 pacotes de personagem + sem anúncios | Inclui Coelho Carteiro, Esquilo Explorador, Ovelhinha, Panda-Vermelho e Lontra Marinha, com seus temas, enfeites e widgets. Remove os anúncios do Início e do Progresso. |

이전 6종 구성으로 테스트 구매한 설치에는 푸들 구매 권리가 캐시로 남을 수 있다.
새 5종 구성은 구매 이력이 없는 테스트 계정·새 설치에서 검증하고, 광고로 연 푸들은
계속 남는지 별도로 확인한다. 이 변경은 기존 저장 권리를 강제로 삭제하지 않는다.

## 앱의 동작

- 가격은 Play가 알려 준 현지 가격을 그대로 보인다. 앱에 가격 문자열을 두지 않는다.
- 결제가 끝나면 산 팩을 바로 입힌다.
- 실행할 때와 앱이 앞으로 돌아올 때 Play 계정의 구매를 조용히 다시 받는다. 설정의
  «구매 복원»은 결과를 말로 알려 준다.
- 환불·지불 거절·기한이 지난 현금 결제는 실행 때 Play에 물어 거둔다. 광고를 보고 연
  팩은 거두지 않는다 — 광고 본 수는 구매 장부와 따로 저장한다.
- 결제 대기(편의점 현금 결제, 보호자 승인)는 Play가 확정할 때까지 팩을 잠근 채 기다린다.
- 결제를 받았는데 저장에 실패하면 구매를 완료하지 않고 둔다. 다음 실행에 Play가 다시
  보내 그때 지급한다.
- 결제는 Android에서만 켠다. 다른 플랫폼에서는 팩 화면이 «이 기기에서는 구매할 수
  없어요»라고 말하고, 번들 카드와 구매 복원 행은 보이지 않는다.

## 출시 전 확인

1. Play Console > 수익 창출 > 인앱 상품에 위 상품 ID를 만들고 가격을 정한 뒤 **활성화**한다.
2. 라이선스 테스터 계정을 등록하고, 비공개 테스트 트랙 빌드로 각 상품을 사 본다.
   테스트 카드의 «항상 승인», «항상 거절», «지연 결제»를 모두 써 본다.
3. 앱을 지웠다가 같은 계정으로 다시 설치해 복원을 확인한다.
4. Play Console에서 테스트 구매를 환불하고 앱을 다시 켜 회수를 확인한다.
5. 개인정보처리방침(`docs/privacy/index.html`) 6장이 공개 주소에 올라갔는지 확인한다.
6. 데이터 안전성 설문을 다시 본다. 앱은 구매 결과를 기기 밖으로 보내지 않지만,
   결제 처리는 Google Play가 한다.
