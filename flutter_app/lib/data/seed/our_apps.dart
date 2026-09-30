import '../../l10n/app_localizations.dart';

/// LOOPET을 만든 사람들의 다른 앱 하나. «추천 앱» 화면이 보여 주는 모양 그대로다.
///
/// 이름은 모든 언어에서 스토어 표기 그대로 두고, 분류와 소개만 번역한다. 둘이
/// 문자열이 아니라 함수인 이유는 [ReleaseNote.lines]와 같다 — gen-l10n은 키로
/// 찾아볼 map이 아니라 타입이 붙은 getter를 내준다.
class OurApp {
  const OurApp({
    required this.packageName,
    required this.name,
    required this.icon,
    required this.kind,
    required this.blurb,
  });

  /// Play 페이지를 여는 application id.
  final String packageName;

  final String name;

  /// `assets/apps/` 아래에 함께 넣은 런처 아이콘.
  final String icon;

  /// 무엇을 위한 앱인지 한 단어. 이름 아래에 보인다.
  final String Function(AppLocalizations) kind;

  final String Function(AppLocalizations) blurb;
}

/// 설치가 이 화면에서 왔다는 것을 각 앱의 Play Console에 알린다.
const ourAppsReferrer = 'utm_source=loopet&utm_medium=our_apps';

/// 화면이 보여 줄 앱, 오래된 것부터.
///
/// 카드는 모두 같은 크기이고 어느 것도 표시를 달지 않으니, 선호로 읽힐 수 있는
/// 것은 순서뿐이다. 출시 순서는 아무것도 말하지 않는다.
/// **Play에 공개된 앱만** 들어간다 — 버튼을 눌러 «항목을 찾을 수 없음»에
/// 닿는 카드는 카드가 없느니만 못하다. Sobrita는 공개되면 합류한다.
final ourApps = <OurApp>[
  OurApp(
    packageName: 'com.randomfocus.app',
    name: 'RandomFocus',
    icon: 'assets/apps/randomfocus.png',
    kind: (l10n) => l10n.ourAppsRandomFocusKind,
    blurb: (l10n) => l10n.ourAppsRandomFocusBlurb,
  ),
];
