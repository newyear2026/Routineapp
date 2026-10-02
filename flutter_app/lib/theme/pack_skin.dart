import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// 팩이 **어떻게 보이는가** — 이름, 화면 장식, 원판 색, 홈 위젯 미리보기.
///
/// [CharacterPack]은 무엇을 파는가(그림·색 변형·데코·판매 방식)를 말하고,
/// 이 값은 그것을 화면에 어떻게 얹는가를 말한다. 화면은 팩 ID를 비교하지
/// 않고 이 값만 읽는다 — 그래야 팩을 더할 때 고칠 곳이 `pack_skin_catalog.dart`
/// 한 곳으로 모인다. 새 팩 체크리스트는 `docs/CHARACTER_PACK_SPEC.md`에 있다.
///
/// 이름과 소개가 문자열이 아니라 함수인 이유는 [ReleaseNote.lines]와 같다 —
/// gen-l10n은 키로 찾아볼 map이 아니라 타입이 붙은 getter를 내준다.
class PackSkin {
  const PackSkin({
    required this.name,
    required this.tagline,
    required this.decorStyle,
    required this.homeScene,
    required this.widget,
    this.appDial = const DialPalette(),
    this.timedScene,
  });

  final String Function(AppLocalizations) name;
  final String Function(AppLocalizations) tagline;

  /// 홈 밖 화면(설정·진행·루틴·루틴 추가·팩 상세)의 머리 장식 계열.
  final PackDecorStyle decorStyle;

  /// 홈 원판 둘레의 장면.
  final HomeSceneSpec homeScene;

  /// 앱 홈 원판의 색. 비워 둔 값은 기본 원판 색을 쓴다.
  final DialPalette appDial;

  /// 홈 화면 위젯의 앱 안 미리보기. 네이티브 위젯은 이 값을 미러링한다.
  final PackWidgetSkin widget;

  /// 기기 시각에 따라 홈과 메뉴에 쓰는 상단·카드 장면.
  final PackTimedScene? timedScene;
}

enum PackSceneStyle {
  squirrel,
  starlight,
  poodle,
  stargazer,
  postal,
  cloud,
  teashop,
  seaside
}

enum PackScenePhase {
  morning,
  day,
  sunset,
  night;

  static PackScenePhase fromHour(int hour) {
    if (hour >= 5 && hour < 11) return morning;
    if (hour >= 11 && hour < 17) return day;
    if (hour >= 17 && hour < 20) return sunset;
    return night;
  }
}

/// 네 시간대의 상단/카드 그림을 한 팩에서 정의한다.
class PackTimedScene {
  const PackTimedScene({
    required this.style,
    required List<String> headers,
    required List<String> cards,
    this.nightBodyColor,
  })  : _headers = headers,
        _cards = cards,
        _header = null,
        _card = null,
        graded = false;

  /// 두 개의 독립 구도에 공통 시간대 조명을 입힌다.
  const PackTimedScene.graded({
    required this.style,
    required String header,
    required String card,
  })  : _headers = const [],
        _cards = const [],
        _header = header,
        _card = card,
        graded = true,
        nightBodyColor = null;

  final PackSceneStyle style;
  final List<String> _headers;
  final List<String> _cards;
  final String? _header;
  final String? _card;
  final bool graded;
  List<String> get headers => graded ? List.filled(4, _header!) : _headers;
  List<String> get cards => graded ? List.filled(4, _card!) : _cards;

  /// 밤에만 본문 색을 바꿀 팩에 지정한다. null이면 팩의 기본 페이지 색을 쓴다.
  final Color? nightBodyColor;

  String headerAt(int hour) => headers[PackScenePhase.fromHour(hour).index];
  String cardAt(int hour) => cards[PackScenePhase.fromHour(hour).index];
  bool lightHeaderAt(int hour) =>
      PackScenePhase.fromHour(hour) == PackScenePhase.night;
}

/// 홈 밖 화면의 머리 장식 계열.
///
/// 화면마다 장식 배치가 달라 좌표를 데이터로 옮기면 화면 수만큼 표가 는다.
/// 그래서 팩은 **계열**만 고르고 배치는 화면이 정한다. 새 계열이 필요한
/// 팩이면 여기에 값을 더하고, 각 화면의 `switch`가 빠진 곳을 알려 준다.
enum PackDecorStyle {
  /// 하늘 그림(`*-sky.png`)과 구름을 머리에 얹는다.
  sky,

  /// 하늘 그림 없이 잎과 데이지를 흩뿌린다.
  garden,
}

/// 원판을 그리는 색. null은 그 자리의 기본색이다.
class DialPalette {
  const DialPalette({
    this.dial,
    this.surface,
    this.track,
    this.pointer,
    this.hourLabel,
    this.tick,
    this.centerLabel,
  });

  /// 계단 원판의 바깥 면.
  final Color? dial;

  /// 원판 안쪽 원반.
  final Color? surface;

  /// 24시간 트랙.
  final Color? track;

  /// 현재 시각 포인터.
  final Color? pointer;

  final Color? hourLabel;
  final Color? tick;

  /// 가운데 시각 아래 딱지의 바탕.
  final Color? centerLabel;
}

/// 홈 원판 둘레의 장면. 원판은 가운데 고정이고, 나머지가 [props]다.
class HomeSceneSpec {
  const HomeSceneSpec({
    this.backdrop,
    this.leadSizeFactor = 0.23,
    this.leadSizeMax = 68,
    required this.props,
  });

  /// 원판 뒤에 까는 그림. 없으면 페이지 배경이 그대로 보인다.
  final String? backdrop;

  /// 크기를 적지 않은 소품(주로 대표 데코)의 크기. 장면 폭에 곱하고
  /// [leadSizeMax]로 막는다.
  final double leadSizeFactor;
  final double leadSizeMax;

  /// 원판 위에 적힌 순서대로 그린다 — 뒤에 적힌 것이 위에 온다.
  final List<SceneProp> props;

  double leadSize(double width) =>
      math.min(width * leadSizeFactor, leadSizeMax);
}

/// 장면 폭에 비례하는 거리. `SceneInset(0.08)`은 폭의 8%, `SceneInset.px(-6)`은
/// 폭과 무관하게 -6이다.
class SceneInset {
  const SceneInset(this.fraction, [this.offset = 0]);
  const SceneInset.px(this.offset) : fraction = 0;

  final double fraction;
  final double offset;

  double resolve(double width) => width * fraction + offset;
}

/// 장면에 놓이는 소품 하나 — 데코 그림이거나 정원 잎.
class SceneProp {
  /// `assets/decorations/<asset>.png`. [size]가 없으면 장면의 대표 크기다.
  const SceneProp.deco(
    String this.asset, {
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.size,
    this.key,
  })  : angle = 0,
        mirror = false;

  const SceneProp.leaf({
    required double this.size,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.angle = 0,
    this.mirror = false,
    this.key,
  }) : asset = null;

  /// null이면 정원 잎이다.
  final String? asset;
  final SceneInset? left;
  final SceneInset? top;
  final SceneInset? right;
  final SceneInset? bottom;
  final double? size;
  final double angle;
  final bool mirror;

  /// 테스트가 찾는 키. 없으면 달지 않는다.
  final String? key;
}

/// 홈 화면 위젯 미리보기의 모양.
class PackWidgetSkin {
  const PackWidgetSkin({
    required this.background,
    required this.accent,
    required this.decor,
    this.decorAsset,
    this.textPrimary,
    this.textMuted,
    this.border,
    this.onAccent,
    this.featuredMascot = false,
    this.mascotHalo,
    this.dial = const DialPalette(),
  });

  /// 왼쪽 위에서 오른쪽 아래로 가는 배경 그라디언트.
  final List<Color> background;

  /// 상태 배지 채움.
  final Color accent;

  final WidgetDecor decor;

  /// [WidgetDecor.stamp]가 찍는 데코 이름.
  final String? decorAsset;

  /// null은 `WidgetTheme`의 기본값이다.
  final Color? textPrimary;
  final Color? textMuted;
  final Color? border;
  final Color? onAccent;

  /// 캐릭터를 크게 세우고 원판을 줄인다. 캐릭터가 위젯의 주인공인 팩이다.
  final bool featuredMascot;

  /// 캐릭터 뒤 동그란 후광. null이면 없다.
  final Color? mascotHalo;

  /// 오른쪽 작은 원판의 색.
  final DialPalette dial;
}

/// 위젯 바탕에 까는 장식.
enum WidgetDecor {
  /// 하늘 그림을 흐리게 깐다.
  sky,

  /// 잎 둘과 데이지 하나.
  garden,

  /// 작은 별빛 셋.
  stars,

  /// 오른쪽 위에 [PackWidgetSkin.decorAsset] 하나를 흐리게 찍는다.
  stamp,

  /// 숲 풍경을 흐리게 깐다.
  forest,

  /// 우편배달부 토끼의 아침 마을 풍경.
  dawn,

  /// 달구름 양의 흐린 파스텔 하늘.
  mooncloud,

  /// 비 오는 날의 찻집 풍경.
  teashop,

  /// 햇살이 비치는 잔잔한 바다 풍경.
  seaside,
}
