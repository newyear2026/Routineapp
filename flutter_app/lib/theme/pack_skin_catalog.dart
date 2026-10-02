import 'package:flutter/material.dart';

import '../domain/store/character_pack.dart';
import '../l10n/app_localizations.dart';
import '../widget_medium/widget_theme.dart';
import 'pack_skin.dart';

/// 팩 ID마다의 [PackSkin]. **팩의 겉모습을 적는 곳은 여기 하나다.**
///
/// 키는 `CharacterPackCatalog`의 팩 ID다. 카탈로그에 팩을 더하고 여기를
/// 빠뜨리면 `pack_spec_test.dart`가 빌드를 깨뜨린다.
abstract final class PackSkinCatalog {
  static const _starlightCat = PackSkin(
    name: _starlightName,
    tagline: _starlightTagline,
    decorStyle: PackDecorStyle.sky,
    timedScene: PackTimedScene(
      style: PackSceneStyle.starlight,
      nightBodyColor: Color(0xFFF6F2FA),
      headers: [
        'assets/pack_backgrounds/starlight-header-morning.png',
        'assets/pack_backgrounds/starlight-header-day.png',
        'assets/pack_backgrounds/starlight-header-sunset.png',
        'assets/pack_backgrounds/starlight-header-night.png',
      ],
      cards: [
        'assets/pack_backgrounds/starlight-card-morning.png',
        'assets/pack_backgrounds/starlight-card-day.png',
        'assets/pack_backgrounds/starlight-card-sunset.png',
        'assets/pack_backgrounds/starlight-card-night.png',
      ],
    ),
    homeScene: HomeSceneSpec(
      backdrop: 'assets/decorations/home-sky.png',
      props: [
        SceneProp.deco(
          'plant',
          left: SceneInset(0.08),
          bottom: SceneInset.px(0),
          key: 'home-timetable-plant',
        ),
      ],
    ),
    widget: PackWidgetSkin(
      background: [Color(0xFFFFF4DC), Color(0xFFE6D8FF)],
      accent: WidgetTheme.accent,
      decor: WidgetDecor.sky,
    ),
  );

  static const _poodleGarden = PackSkin(
    name: _poodleName,
    tagline: _poodleTagline,
    decorStyle: PackDecorStyle.garden,
    timedScene: PackTimedScene(
      style: PackSceneStyle.poodle,
      headers: [
        'assets/pack_backgrounds/poodle-header-morning.png',
        'assets/pack_backgrounds/poodle-header-day.png',
        'assets/pack_backgrounds/poodle-header-sunset.png',
        'assets/pack_backgrounds/poodle-header-night.png',
      ],
      cards: [
        'assets/pack_backgrounds/poodle-card-morning.png',
        'assets/pack_backgrounds/poodle-card-day.png',
        'assets/pack_backgrounds/poodle-card-sunset.png',
        'assets/pack_backgrounds/poodle-card-night.png',
      ],
    ),
    homeScene: HomeSceneSpec(
      // 물뿌리개는 화분보다 가로로 넓어 같은 크기면 원판에 닿는다.
      leadSizeFactor: 0.19,
      leadSizeMax: 56,
      props: [
        SceneProp.deco(
          'garden-watering-can',
          left: SceneInset.px(0),
          bottom: SceneInset.px(-6),
          key: 'home-timetable-watering-can',
        ),
        SceneProp.leaf(
          size: 27,
          left: SceneInset(0.01),
          top: SceneInset(0.17),
          mirror: true,
          key: 'home-garden-leaf-left',
        ),
        SceneProp.leaf(
          size: 25,
          right: SceneInset(0.005),
          top: SceneInset(0.25),
          angle: -0.3,
          key: 'home-garden-leaf-right',
        ),
        SceneProp.leaf(
          size: 20,
          left: SceneInset(0.19),
          bottom: SceneInset(0.12),
          angle: 0.5,
        ),
        SceneProp.leaf(
          size: 20,
          right: SceneInset(0.01),
          bottom: SceneInset(0.34),
          mirror: true,
        ),
        SceneProp.deco(
          'garden-daisy',
          right: SceneInset(0.04),
          top: SceneInset(0.08),
          size: 42,
        ),
      ],
    ),
    appDial: DialPalette(
      dial: Color(0xFFEEF9F2),
      track: Color(0xFFC9F1E5),
    ),
    widget: PackWidgetSkin(
      background: [Color(0xFFF7F0FF), Color(0xFFD4F7E8)],
      accent: Color(0xFF078F96),
      decor: WidgetDecor.garden,
    ),
  );

  static const _stargazerCat = PackSkin(
    name: _stargazerName,
    tagline: _stargazerTagline,
    decorStyle: PackDecorStyle.sky,
    timedScene: PackTimedScene.graded(
      style: PackSceneStyle.stargazer,
      header: 'assets/pack_backgrounds/stargazer-scene-header.png',
      card: 'assets/pack_backgrounds/stargazer-scene-card.png',
    ),
    homeScene: HomeSceneSpec(
      props: [
        SceneProp.deco(
          'stargazer-telescope',
          left: SceneInset(0.01),
          bottom: SceneInset.px(0),
        ),
        SceneProp.deco(
          'stargazer-meteor',
          right: SceneInset(0.01),
          top: SceneInset(0.03),
          size: 46,
        ),
        SceneProp.deco(
          'stargazer-celestial-globe',
          right: SceneInset(0.01),
          bottom: SceneInset.px(0),
          size: 46,
        ),
      ],
    ),
    widget: PackWidgetSkin(
      background: [Color(0xFF0B3D4A), Color(0xFF12365B)],
      accent: Color(0xFFF4C430),
      decor: WidgetDecor.stars,
      textPrimary: Color(0xFFFFF9EA),
      textMuted: Color(0xFFD6E6ED),
      border: Color(0xFF668995),
      onAccent: Color(0xFF123041),
      featuredMascot: true,
      mascotHalo: Color(0xFFFFE7A6),
      dial: DialPalette(
        dial: Color(0xFF0A3446),
        track: Color(0xFF1D6A7C),
        pointer: Color(0xFFF4C430),
        hourLabel: Color(0xFFE0F2F0),
        tick: Color(0xFFBCE4E8),
        centerLabel: Color(0xFFFFE295),
      ),
    ),
  );

  static const _postmanRabbit = PackSkin(
    name: _rabbitName,
    tagline: _rabbitTagline,
    decorStyle: PackDecorStyle.sky,
    timedScene: PackTimedScene.graded(
      style: PackSceneStyle.postal,
      header: 'assets/pack_backgrounds/rabbit-scene-header.png',
      card: 'assets/pack_backgrounds/rabbit-scene-card.png',
    ),
    homeScene: HomeSceneSpec(
      props: [
        SceneProp.deco(
          'rabbit-letter',
          left: SceneInset(0.01),
          bottom: SceneInset.px(0),
        ),
        SceneProp.deco(
          'rabbit-carrot-stamp',
          right: SceneInset(0.01),
          top: SceneInset(0.03),
          size: 42,
        ),
        SceneProp.deco(
          'rabbit-satchel',
          right: SceneInset(0.01),
          bottom: SceneInset.px(0),
          size: 44,
        ),
      ],
    ),
    widget: PackWidgetSkin(
      background: [Color(0xFFFFD1C2), Color(0xFFFFEFC9)],
      accent: Color(0xFFE97068),
      decor: WidgetDecor.dawn,
      featuredMascot: true,
      dial: DialPalette(
        dial: Color(0xFFFFE3D0),
        surface: Color(0xFFFFFCF3),
        track: Color(0xFFC5E4CA),
        pointer: Color(0xFFDB665E),
        centerLabel: Color(0xFFFFE9D8),
      ),
    ),
  );

  static const _explorerSquirrel = PackSkin(
    name: _squirrelName,
    tagline: _squirrelTagline,
    decorStyle: PackDecorStyle.garden,
    timedScene: PackTimedScene(
      style: PackSceneStyle.squirrel,
      nightBodyColor: Color(0xFFF6F2FA),
      headers: [
        'assets/pack_backgrounds/squirrel-home-header-morning.png',
        'assets/pack_backgrounds/squirrel-home-header.png',
        'assets/pack_backgrounds/squirrel-home-header-evening.png',
        'assets/pack_backgrounds/squirrel-home-header-night.png',
      ],
      cards: [
        'assets/pack_backgrounds/squirrel-home-card.png',
        'assets/pack_backgrounds/squirrel-home-card.png',
        'assets/pack_backgrounds/squirrel-home-card-evening.png',
        'assets/pack_backgrounds/squirrel-home-card-night.png',
      ],
    ),
    homeScene: HomeSceneSpec(
      props: [
        SceneProp.deco(
          'squirrel-acorn',
          left: SceneInset(0.01),
          bottom: SceneInset.px(0),
        ),
        SceneProp.deco(
          'squirrel-map',
          right: SceneInset(0.01),
          top: SceneInset(0.03),
          size: 43,
        ),
        SceneProp.deco(
          'squirrel-backpack',
          right: SceneInset(0.01),
          bottom: SceneInset.px(0),
          size: 45,
        ),
      ],
    ),
    appDial: DialPalette(
      dial: Color(0xFFF6EBD6),
      surface: Color(0xFFFFFDF5),
      track: Color(0xFFCDDEC1),
      pointer: Color(0xFF8A9E62),
    ),
    widget: PackWidgetSkin(
      background: [Color(0xFFF5E9D4), Color(0xFFD8E8C9)],
      accent: Color(0xFF718B51),
      decor: WidgetDecor.forest,
      textPrimary: Color(0xFF3E3229),
      textMuted: Color(0xFF746C5A),
      border: Color(0xFF9DAE83),
      featuredMascot: true,
      mascotHalo: Color(0xFFFFF2C8),
      dial: DialPalette(
        dial: Color(0xFFF6EBD6),
        surface: Color(0xFFFFFDF5),
        track: Color(0xFFCDDEC1),
        pointer: Color(0xFF718B51),
        centerLabel: Color(0xFFFFE5AE),
      ),
    ),
  );

  static const _mooncloudSheep = PackSkin(
    name: _sheepName,
    tagline: _sheepTagline,
    decorStyle: PackDecorStyle.sky,
    timedScene: PackTimedScene.graded(
      style: PackSceneStyle.cloud,
      header: 'assets/pack_backgrounds/sheep-scene-header.png',
      card: 'assets/pack_backgrounds/sheep-scene-card.png',
    ),
    homeScene: HomeSceneSpec(
      props: [
        SceneProp.deco(
          'sheep-cloud',
          left: SceneInset(0.01),
          bottom: SceneInset.px(0),
        ),
        SceneProp.deco(
          'sheep-moon',
          right: SceneInset(0.02),
          top: SceneInset(0.03),
          size: 43,
        ),
        SceneProp.deco(
          'sheep-book',
          right: SceneInset(0.01),
          bottom: SceneInset.px(0),
          size: 44,
        ),
      ],
    ),
    appDial: DialPalette(
      dial: Color(0xFFE7ECFF),
      surface: Color(0xFFFFFCFF),
      track: Color(0xFFCFC8F2),
      pointer: Color(0xFF6577C8),
    ),
    widget: PackWidgetSkin(
      background: [Color(0xFFDCE9FF), Color(0xFFE9DDFF)],
      accent: Color(0xFF6577C8),
      decor: WidgetDecor.mooncloud,
      textPrimary: Color(0xFF242548),
      textMuted: Color(0xFF626A92),
      border: Color(0xFF8D99C5),
      featuredMascot: true,
      mascotHalo: Color(0xFFFFF0C2),
      dial: DialPalette(
        dial: Color(0xFFE7ECFF),
        surface: Color(0xFFFFFCFF),
        track: Color(0xFFCFC8F2),
        pointer: Color(0xFF6577C8),
        hourLabel: Color(0xFF242548),
        tick: Color(0xFF626A92),
        centerLabel: Color(0xFFFFF0C2),
      ),
    ),
  );

  static const _redPandaTeashop = PackSkin(
    name: _redPandaName,
    tagline: _redPandaTagline,
    decorStyle: PackDecorStyle.sky,
    timedScene: PackTimedScene.graded(
      style: PackSceneStyle.teashop,
      header: 'assets/pack_backgrounds/redpanda-scene-header.png',
      card: 'assets/pack_backgrounds/redpanda-scene-card.png',
    ),
    homeScene: HomeSceneSpec(
      props: [
        SceneProp.deco(
          'redpanda-teapot',
          left: SceneInset(0.01),
          bottom: SceneInset.px(0),
        ),
        SceneProp.deco(
          'redpanda-window',
          right: SceneInset(0.01),
          top: SceneInset(0.03),
          size: 43,
        ),
        SceneProp.deco(
          'redpanda-teacup',
          right: SceneInset(0.01),
          bottom: SceneInset.px(0),
          size: 44,
        ),
      ],
    ),
    appDial: DialPalette(
      dial: Color(0xFFF8EAD7),
      surface: Color(0xFFFFFDF6),
      track: Color(0xFFC7DED4),
      pointer: Color(0xFF376D68),
    ),
    widget: PackWidgetSkin(
      background: [Color(0xFFF9EBD7), Color(0xFFD9ECE8)],
      accent: Color(0xFF376D68),
      decor: WidgetDecor.teashop,
      textPrimary: Color(0xFF3D302D),
      textMuted: Color(0xFF776B65),
      border: Color(0xFF8EABA1),
      featuredMascot: true,
      mascotHalo: Color(0xFFFFF0CF),
      dial: DialPalette(
        dial: Color(0xFFF8EAD7),
        surface: Color(0xFFFFFDF6),
        track: Color(0xFFC7DED4),
        pointer: Color(0xFF376D68),
        hourLabel: Color(0xFF3D302D),
        tick: Color(0xFF776B65),
        centerLabel: Color(0xFFFFE6B9),
      ),
    ),
  );

  static const _otterSeaside = PackSkin(
    name: _otterName,
    tagline: _otterTagline,
    decorStyle: PackDecorStyle.sky,
    timedScene: PackTimedScene.graded(
      style: PackSceneStyle.seaside,
      header: 'assets/pack_backgrounds/otter-scene-header.png',
      card: 'assets/pack_backgrounds/otter-scene-card.png',
    ),
    homeScene: HomeSceneSpec(
      props: [
        SceneProp.deco('otter-shell',
            left: SceneInset(0.01), bottom: SceneInset.px(0)),
        SceneProp.deco('otter-seaglass',
            right: SceneInset(0.01), top: SceneInset(0.03), size: 43),
        SceneProp.deco('otter-wave',
            right: SceneInset(0.01), bottom: SceneInset.px(0), size: 44),
      ],
    ),
    appDial: DialPalette(
      dial: Color(0xFFFFF1D7),
      surface: Color(0xFFFFFDF5),
      track: Color(0xFFD7F5F2),
      pointer: Color(0xFF157F8E),
    ),
    widget: PackWidgetSkin(
      background: [Color(0xFFFFF1D7), Color(0xFFD7F5F2)],
      accent: Color(0xFF157F8E),
      decor: WidgetDecor.seaside,
      textPrimary: Color(0xFF29444A),
      textMuted: Color(0xFF59777A),
      border: Color(0xFF77B9BE),
      featuredMascot: true,
      mascotHalo: Color(0xFFFFF0D8),
      dial: DialPalette(
        dial: Color(0xFFFFF1D7),
        surface: Color(0xFFFFFDF5),
        track: Color(0xFFD7F5F2),
        pointer: Color(0xFF157F8E),
        hourLabel: Color(0xFF29444A),
        tick: Color(0xFF59777A),
        centerLabel: Color(0xFFFFE7C3),
      ),
    ),
  );

  /// 팩 ID → 겉모습. 순서는 뜻이 없다.
  static const byPackId = <String, PackSkin>{
    'cat_starlight': _starlightCat,
    'poodle_garden': _poodleGarden,
    'cat_stargazer': _stargazerCat,
    'rabbit_postman': _postmanRabbit,
    'squirrel_explorer': _explorerSquirrel,
    'sheep_mooncloud': _mooncloudSheep,
    'redpanda_teashop': _redPandaTeashop,
    'otter_seaside': _otterSeaside,
  };

  /// [pack]의 겉모습. 등록되지 않은 팩은 기본 팩의 겉모습으로 그린다 —
  /// 화면이 터지는 것보다 낫고, 빠뜨린 것은 테스트가 잡는다.
  static PackSkin of(CharacterPack pack) => byPackId[pack.id] ?? _starlightCat;
}

// gen-l10n getter는 const 식에 쓸 수 없어 최상위 함수로 넘긴다.
String _starlightName(AppLocalizations l10n) => l10n.packStarlightCatName;
String _starlightTagline(AppLocalizations l10n) => l10n.packStarlightCatTagline;
String _poodleName(AppLocalizations l10n) => l10n.packPoodleGardenName;
String _poodleTagline(AppLocalizations l10n) => l10n.packPoodleGardenTagline;
String _stargazerName(AppLocalizations l10n) => l10n.packStargazerName;
String _stargazerTagline(AppLocalizations l10n) => l10n.packStargazerTagline;
String _rabbitName(AppLocalizations l10n) => l10n.packPostmanRabbitName;
String _rabbitTagline(AppLocalizations l10n) => l10n.packPostmanRabbitTagline;
String _squirrelName(AppLocalizations l10n) => l10n.packExplorerSquirrelName;
String _squirrelTagline(AppLocalizations l10n) =>
    l10n.packExplorerSquirrelTagline;
String _sheepName(AppLocalizations l10n) => l10n.packMooncloudSheepName;
String _sheepTagline(AppLocalizations l10n) => l10n.packMooncloudSheepTagline;
String _redPandaName(AppLocalizations l10n) => l10n.packRedPandaTeashopName;
String _redPandaTagline(AppLocalizations l10n) =>
    l10n.packRedPandaTeashopTagline;
String _otterName(AppLocalizations l10n) => l10n.packOtterSeasideName;
String _otterTagline(AppLocalizations l10n) => l10n.packOtterSeasideTagline;
