import '../../l10n/app_localizations.dart';

/// 노트 화면이 몇 개 버전까지 들고 있을지.
///
/// 여기 남기는 버전 하나하나가 **모든 로케일에서 줄 수만큼의 ARB 키**를 먹는데,
/// v1.4를 쓰는 사람이 v1.1에서 무엇이 바뀌었는지 읽으려고 이 화면을 열지는
/// 않는다. 그러므로 릴리스를 추가한다는 것은 아래에서 가장 오래된 항목을 빼고
/// 그 키를 세 ARB에서 지우는 일이다 — 뒤에 붙이고 넘어가는 일이 아니다.
/// `release_notes_test.dart`가 이 선을 넘으면 빌드를 깨뜨린다.
const releaseNoteRetention = 5;

/// 출시된 버전 하나와 그 버전에서 바뀐 것.
///
/// 줄이 문자열이 아니라 함수인 이유는, 노트가 화면이 그려지는 로케일로 읽혀야
/// 하는데 gen-l10n은 키로 찾아볼 수 있는 map이 아니라 타입이 붙은 getter를
/// 내주기 때문이다.
class ReleaseNote {
  const ReleaseNote({
    required this.version,
    required this.releasedOn,
    required this.lines,
  });

  /// 빌드 번호를 뗀 `pubspec.yaml`의 버전과 같다. 그것이 곧
  /// `AppVersion.version`이 알려 주는 값이고, 현재 카드를 표시하는 기준이다.
  final String version;

  final DateTime releasedOn;
  final List<String Function(AppLocalizations)> lines;
}

/// 각 출시 버전에서 바뀐 것, 최신이 먼저.
///
/// **사용자에게 실제로 닿은 버전만** 여기 들어가고, 그중에서도 읽는 사람이
/// 알아챌 변화만 들어간다. 변경점 전체가 내부 사정인 릴리스 — 광고 판정, 빌드
/// 배관 — 는 항목 없이 나가고 아무것도 알리지 않는다. 항목이 없다는 것을
/// `ReleaseAnnouncements`가 «말할 것 없음»으로 읽는다.
///
/// 1.0.0은 여기 없다. Figma Make 스캐폴드가 달고 있던 번호이고 스토어에 올라간
/// 적이 없다 — 닿지 않은 버전의 «바뀐 점»은 지어낸 이력이다.
final releaseNotes = <ReleaseNote>[
  ReleaseNote(
    version: '1.0.1',
    releasedOn: DateTime(2026, 9, 22),
    lines: [
      (l10n) => l10n.releaseNote101Snooze,
      (l10n) => l10n.releaseNote101PixelClouds,
    ],
  ),
];
