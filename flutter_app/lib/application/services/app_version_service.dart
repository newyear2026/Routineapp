import 'package:package_info_plus/package_info_plus.dart';

/// 지금 돌고 있는 빌드 — 설정의 «앱 버전» 행이 보여 주는 값.
class AppVersion {
  const AppVersion({required this.version, required this.buildNumber});

  /// 세 마디 이름 — `1.0.1`. 릴리스 노트가 이 값으로 묶인다.
  final String version;

  /// 그 뒤의 빌드 — Android는 `versionCode`, iOS는 `CFBundleVersion`.
  /// 같은 버전의 두 빌드는 여기서만 갈리는데, 문의를 받을 때 필요한 것이
  /// 바로 그 구분이고 릴리스 노트가 무시해야 하는 것도 바로 그 구분이다.
  final String buildNumber;

  String get displayLabel => '$version ($buildNumber)';

  @override
  bool operator ==(Object other) =>
      other is AppVersion &&
      other.version == version &&
      other.buildNumber == buildNumber;

  @override
  int get hashCode => Object.hash(version, buildNumber);
}

typedef AppVersionLoader = Future<AppVersion?> Function();

/// 플랫폼에서 버전을 읽는다. 읽을 수 없으면 null.
///
/// 하드코딩한 대체값이 아니라 null인 이유는, 플러그인이 위젯 테스트와 채널이
/// 없는 호스트에서 쓸 수 없고 여기 적어 둔 상수는 실제 버전이 그것을 지나치는
/// 순간부터 낡기 시작하는데도 화면에서는 여전히 권위 있어 보이기 때문이다.
/// 설정 행은 대신 줄표를 보여 주고, 노트 화면은 어떤 카드도 현재로 표시하지
/// 않는다.
Future<AppVersion?> loadAppVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return AppVersion(version: info.version, buildNumber: info.buildNumber);
  } on Object {
    return null;
  }
}
