# 캐릭터 팩 규격

캐릭터 팩은 **파는 단위이자 고르는 단위**다. 캐릭터 그림, 색 변형, 데코,
화면 장식, 홈 화면 위젯 모양이 한 묶음으로 움직인다. 이 문서는 팩 하나가
갖춰야 할 것과 새 팩을 더하는 순서를 정한다.

규칙 대부분은 `test/pack_spec_test.dart`와 `test/bundled_assets_budget_test.dart`가
강제한다. 규칙을 바꾸면 이 문서와 테스트를 함께 고친다.

## 팩을 이루는 것

| 무엇 | 어디 | 누가 읽나 |
| --- | --- | --- |
| 정의(ID·그림 폴더·색 변형·데코·판매 방식) | `lib/data/store/character_pack_catalog.dart` | 스토어·선택·소유 판정 |
| 겉모습(이름·장식·원판 색·위젯 미리보기) | `lib/theme/pack_skin_catalog.dart` | 앱 화면 전부 |
| 포즈 그림 6종 | `assets/characters/<id>/v1/approved/` | `AnimatedCat`, 위젯 미리보기 |
| 포즈별 그림 영역 | `lib/widgets/ds/animated_cat.dart`의 `CharacterArtwork` | `AnimatedCat` |
| 데코 그림 | `assets/decorations/<decoId>.png` | 홈 장면, 위젯 |
| 색 변형 | `lib/theme/app_theme_preset.dart` | 앱 테마 |
| 이름·소개 문구 | `lib/l10n/app_*.arb` 5개 언어 | 스토어·설정 |
| Android 위젯 | `RoutineWidgetSkin.kt` + `res/drawable*` | 홈 화면 위젯 3종 |
| iOS 위젯 | `RoutineWidgetExtension.swift`의 `WidgetPackSkin` + `Artwork/` | 홈 화면 위젯 |

**화면 코드는 팩 ID를 비교하지 않는다.** 팩마다 다른 것은 모두 `PackSkin`
(앱), `RoutineWidgetSkin`(Android), `WidgetPackSkin`(iOS)에 적고, 화면은
그 값만 읽는다. 팩 ID를 글자로 적어도 되는 파일은 `pack_spec_test.dart`의
허용 목록에 있다.

## ID

- `<종>_<테마>` 꼴의 소문자와 밑줄이다. 예: `cat_starlight`, `rabbit_postman`.
- 그림 폴더 이름(`characterId`)도 같은 값을 쓴다.
- 한 번 출시한 ID는 바꾸지 않는다. 사용자가 고른 팩(`AppSettings.characterPackId`)과
  홈 화면 위젯 데이터가 이 값을 저장한다. 모르는 ID는 기본 팩으로 떨어진다.

## 포즈 그림

- 6종: `idle`(대기), `activity`(활동), `focus`(집중), `complete`(완료),
  `rest`(휴식), `guide`(안내). 홈이 루틴 상태에 따라 고르므로 하나도 빠지면 안 된다.
- **384×384 투명 PNG(RGBA), 한 장 130KB 이하.** 앱은 `cacheWidth: 384`로
  디코딩하므로 3x 기기까지 이 크기면 충분하다.
- 앱에 싣는 것은 `approved/`의 6장뿐이다. 1254px 원본과 시안은 `approved/`
  밖(같은 `v1/` 폴더나 `design/`)에 두고 `pubspec.yaml`에 올리지 않는다.
- 6장 모두 `pubspec.yaml`에 파일 단위로 등록한다. 폴더째 올리면 옆의
  README까지 번들된다.
- 캐릭터마다 포즈별 그림 영역(불투명 경계)을 재서 `CharacterArtwork.byCharacter`에
  적는다. `AnimatedCat`이 이 값으로 포즈마다 크기와 바닥선을 맞춘다.
- 그림을 다시 그리면 `v2/` 폴더를 새로 만들고 `assetVersion`을 올린다. 옛 빌드가
  깨지지 않게 하기 위해서다.

## 데코

- `assets/decorations/<decoId>.png`, 투명 PNG, 긴 변 384px 이하, 130KB 이하.
- 팩의 `decoIds`에 적은 것만 그 팩의 장면과 위젯에 쓴다. 데코는 팩끼리 나눠
  쓰지 않는다.
- 정원 잎(`garden-leaf`)처럼 장식 계열이 제공하는 그림은 `decoIds`에 넣지 않는다.

## 판매 방식

| `availability` | 여는 방법 |
| --- | --- |
| `included` | 기본 제공 |
| `forSale` | Play 인앱 상품. `productId`는 `loopet.pack.<id>`. 5종 묶음은 `StoreProductCatalog.bundlePackIds`에 지정된 팩만 포함한다 |
| `rewardedUnlock` | 보상형 광고 2회. 5종 구매 묶음에는 포함하지 않는다 |
| `launchGift` | 출시 기간에 시작한 사용자. 팔지 않는다 |
| `comingSoon` | 그림이 아직 없다 |

판매 팩은 Play Console에 상품을 등록해야 가격이 뜬다. 등록할 목록과 가격은
`docs/STORE_PRODUCTS.md`에 있다.

## 색 변형

- 팩의 `paletteIds`는 `AppThemePreset.all`에 있는 프리셋 ID다. 없는 ID는
  조용히 `soft_day`로 떨어지므로 테스트가 막는다.
- 하나뿐이면 그 색으로 고정한다. 여럿이면 사용자가 그중에서 고른다(기본 팩).

## 겉모습 (`PackSkin`)

| 필드 | 뜻 |
| --- | --- |
| `name`, `tagline` | 번역 문구. `pack<이름>Name`, `pack<이름>Tagline` 키 |
| `decorStyle` | 홈 밖 화면(설정·진행·루틴·루틴 추가·팩 상세)의 머리 장식 계열. `sky` 또는 `garden` |
| `homeScene` | 홈 원판 둘레의 장면: 배경 그림(`backdrop`)과 소품(`props`) |
| `appDial` | 앱 홈 원판 색. 비운 값은 기본색 |
| `widget` | 홈 화면 위젯 미리보기: 배경 그라디언트, 배지색, 글자색, 장식, 캐릭터 크기, 작은 원판 색 |
| `timedScene` | 선택 사항. 네 시간대 상단·홈 카드 그림과 움직임 계열 |

### 시간대 장면 (`timedScene`)

현재 9개 팩 모두 `PackTimedScene`을 쓴다. `PackSkinCatalog`가 장면과
움직임 계열을 정의하며 화면마다 팩 ID를 분기하지 않는다.

- 기존 다람쥐·별빛 고양이·푸들: `headers` 4장과 `cards` 4장으로 개별 시간대 자산을 지정한다.
- 유성 관측 고양이·토끼·양·랫서팬더·해달·펭귄: `PackTimedScene.graded`에
  서로 다른 상단 `header`와 카드 `card` 원화 두 장을 지정한다.
  `ScenicPackBackdrop`/`sceneLighting`이 아침·낮·노을·밤의 조명을 적용한다.
  해·달은 상단에서만 픽셀로 그리고, 실내 찻집에는 그리지 않는다.
  캐릭터와 글자에는 색 보정을 적용하지 않는다.
  밤의 상단과 카드는 서로 다른 조명 강도를 쓴다. 카드는 달빛 아래 풍경처럼
  밝게 남겨 글자 뒤를 과도한 흰색 레이어로 가리지 않는다.
  밝은 레이어의 투명 끝 색은 `Color(0x00FFF9EF)`처럼 RGB를 유지한다.
  `Colors.transparent`(투명 검정)로 보간하면 회색 띠가 생길 수 있다.

순서는 **아침 05–11, 낮 11–17, 노을 17–20, 밤 20–05**이며 기기 시각으로
고른다. 상단과 카드에는 같은 시간대의 **서로 다른 구도**를 쓴다. 상단을
카드에 그대로 복사하면 이음새와 장면의 깊이가 어색해진다.

- 상단은 화면 양쪽 끝까지 채우고 아래쪽은 본문 배경으로 서서히 흐린다.
- 카드 왼쪽 글자 영역은 밝게 유지한다. 밤의 상단 글자는 밝은 색으로 바꾼다.
- 본문 바탕은 기본 팩 테마 색을 유지한다. 밤에 본문까지 바꿔야 할 때만
  `nightBodyColor`를 지정한다.
- 바탕 그림은 고정한다. 작은 입자만 움직이며 홈은 6초, 진행·루틴은 12초
  반복으로 약하게, 설정은 정지한다. 시스템의 애니메이션 축소와 앱 백그라운드를 따른다.
- 그림은 `assets/pack_backgrounds/`에 PNG로 저장하고 `pubspec.yaml`에
  개별 등록한다. 네 시간대 모두 유효한 상단/카드 자산을 참조하는지 테스트한다.
- 화면은 팩 ID 대신 `PackTimeScene.of(context, hour)`를 읽는다.
  계절별 움직임이나 파티클 스타일이 새로 필요하면 `PackSceneStyle`과
  해당 배경 위젯을 추가한다.

#### 추가 여섯 팩의 움직임

| 팩 / style | 아침·낮 | 노을 | 밤 |
| --- | --- | --- | --- |
| 유성 관측 / stargazer | 옅은 빛 반짝임 | 금빛 반짝임 | 별빛과 짧은 유성 |
| 우편배달부 / postal | 꽃잎, 낮에는 작은 나비 | 따뜻한 꽃잎 | 반딧불 |
| 달구름 / cloud | 작은 구름 조각 | 분홍 구름 조각 | 별빛 |
| 찻집 / teashop | 창가 빗방울, 카드의 김 | 따뜻한 창가와 김 | 어두운 창가와 김 |
| 해변 / seaside | 수면 반짝임 | 금빛 수면 | 달빛 수면과 별 |
| 눈길 / snowwalk | 작은 눈꽃 | 노을빛 눈꽃 | 달빛 눈꽃 |

이 여섯 팩은 본문 색을 모든 시간대에 고정하고 `nightBodyColor`를 지정하지 않는다.
홈 카드는 공통 최소 높이 164dp를 유지한다. 원판 주변에는 기존 소품만 두며,
예전 가로 배경을 원판 뒤에 늘려 그려서 장면이 한 번 더 반복되지 않게 한다.
움직임은 오른쪽 풍경 안에서만, 홈 6초 / 진행·루틴 12초 반복이다.
설정은 정적이며, 접근성의 애니메이션 축소·숨겨진 탭·앱 백그라운드에서 중지한다.
시간대는 기기 현지 시각의 고정 구간으로, 실제 일출·일몰 계산은 하지 않는다.

이 변경은 **앱 내부 4개 메뉴**에 적용된다. OS 홈 위젯의 정적 배경과 갱신 정책은 별도다.
`design/remaining-pack-scenes/prompts.json`에 built-in image_gen 원화 생성 프롬프트와
원본 경로를 기록했다. 번들에는 최적화한 원화 10장(약 2.9MB)만 싣는다.
`tool/render_pack_time_scenes.dart`로 실제 홈 20장과 카드 상단·높이를 검증한다.

숲이나 구름처럼 위젯 전체에 까는 팩 전용 풍경은 `assets/pack_backgrounds/`에
두고, Android `drawable-nodpi/`와 iOS `Artwork/`에도 같은 그림을 둔다.
루틴 글자 아래에서는 투명도를 낮춰 읽기 쉽게 한다.

- 장면의 소품은 `SceneInset`으로 자리를 적는다. 장면 폭의 비율(`SceneInset(0.08)`)이나
  고정 거리(`SceneInset.px(-6)`)다. 가로·세로 각각 한쪽만 적는다.
- 크기를 적지 않은 소품은 장면의 대표 크기(`leadSizeFactor`, `leadSizeMax`)를 쓴다.
- 새 장식 계열이 필요하면 `PackDecorStyle`에 값을 더한다. 각 화면의 분기가
  빠진 곳을 알려 준다.

## 홈 화면 위젯

위젯은 Flutter(앱 안 미리보기), Android, iOS 세 벌로 그려진다. 앱 미리보기 값이
기준이고, 네이티브는 그 값을 미러링한다.

**Android** (`android/app/src/main`)

- `RoutineWidgetSkin.forPack`에 한 갈래를 더한다. 원판 색(`RingColors`),
  링 위젯(`MediumSkin`), 타임라인·카드 위젯(`VariantSkin`)을 채운다.
- 리소스 이름은 `<name>`을 팩의 짧은 이름으로 해서 맞춘다.
  - `res/drawable/widget_medium_bg_<name>.xml`: 링 위젯 배경
  - `res/drawable/widget_badge_bg_<name>.xml`: 상태 배지 배경
  - `res/drawable-nodpi/widget_<name>.png`: 링 위젯 캐릭터(`idle` 포즈 복사본)
  - `res/drawable-nodpi/widget_variant_<name>.png`: 타임라인·카드 위젯 캐릭터
- 타임라인·카드 위젯은 두 방식 중 하나를 고른다.
  - `STANDARD`: 기본 장면에 값만 바꿔 얹는다. `StandardScene`(768×512 배경 그림
    `widget_bg_timeline_<name>.png`, 다음 일정 패널 색, 아이콘, 구분선)을 채운다.
  - 장면을 통째로 새로 그리는 팩은 `VariantStyle`에 자기 이름을 더하고,
    `RoutineWidgetVariantBitmap`에 그리기 함수를 더한다(`STARGAZER`, `RABBIT` 참고).

**iOS** (`ios/RoutineWidgetExtension`)

- `WidgetPackSkin.forPack`에 `case "<id>":`를 더한다.
- `Artwork/widget_<name>.png`(`idle` 포즈 복사본)를 넣는다.

## 새 팩 체크리스트

1. ID를 정한다(`<종>_<테마>`).
2. 포즈 6종을 384×384 RGBA로 `assets/characters/<id>/v1/approved/`에 넣고
   `pubspec.yaml`에 등록한다. 그림 영역을 재서 `CharacterArtwork.byCharacter`에 적는다.
3. 데코를 `assets/decorations/`에 넣고 `pubspec.yaml`에 등록한다.
4. 색 변형을 `AppThemePreset`에 더하고 `all`에 넣는다.
5. `CharacterPackCatalog`에 팩을 정의하고 `all`에 넣는다. 팔 팩이면 `forSale`과
   `productId`를 주고, Play Console에 상품을 등록한다(`docs/STORE_PRODUCTS.md`).
6. 이름·소개 문구를 5개 언어 arb에 넣는다.
7. `PackSkinCatalog.byPackId`에 겉모습을 적는다. 시간대 장면이 있으면
   상단·카드 그림 4장씩 또는 `PackTimedScene.graded` 원화 2장과 움직임 계열을 더한다.
8. Android: 리소스 4종과 `RoutineWidgetSkin.forPack`.
9. iOS: `Artwork/widget_<name>.png`와 `WidgetPackSkin.forPack`.
10. `flutter test`를 돌린다. 빠진 조각은 `pack_spec_test.dart`가 하나씩 짚는다.
11. 기기에서 홈 화면 위젯 3종(링·타임라인·카드)을 직접 본다. 네이티브 위젯의
    그림은 테스트가 보지 못한다.

## 테스트가 보는 것과 보지 못하는 것

`pack_spec_test.dart`와 `bundled_assets_budget_test.dart`가 보는 것:

- 포즈 6종의 존재·크기·RGBA·용량·pubspec 등록, 그림 영역
- 데코의 존재·크기·RGBA·용량·pubspec 등록, 팩끼리 겹치지 않음
- 색 변형이 실제 프리셋인지
- 모든 팩에 `PackSkin`이 있는지, 장면·위젯이 팩의 데코만 쓰는지
- 5개 언어 이름·소개
- 앱·Android·iOS 코드가 팩 ID를 등록표 밖에서 비교하지 않는지
- Android·iOS 등록표가 모든 팩을 아는지, iOS 위젯 그림이 있는지

보지 못하는 것:

- 네이티브 위젯이 실제로 어떻게 보이는지. 기기나 에뮬레이터에서 확인한다.
- 그림의 화풍·바닥선이 다른 팩과 어울리는지. `tool/render_*_preview.dart`로
  시안을 뽑아 본다.
