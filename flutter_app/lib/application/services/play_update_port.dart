import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/update/app_update_port.dart';

/// Google Play에 새 빌드가 기다리는지 묻고, 스토어 페이지를 연다.
///
/// In-App Update API에서 가져오는 것은 **질문뿐**이다. 업데이트 자체는 이걸로
/// 시작하지 않는다. `performImmediateUpdate`는 구글의 전체 화면 흐름을
/// 사용자 앞에 세우는데 그건 이 앱이 쓸 수 있는 화면이 아니고,
/// `startFlexibleUpdate`는 시작하지도 않은 설치를 끝낼 책임을 LOOPET에
/// 지운다. 스토어 페이지로 넘기면 사용자가 보는 다이얼로그 하나는 앱의
/// 말투로 남고, 설치는 그것을 소유한 앱에 맡긴다.
final class PlayUpdatePort implements AppUpdatePort {
  const PlayUpdatePort();

  @override
  bool get canCheck => true;

  @override
  Future<PendingUpdate?> check() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return null;
      }
      final versionCode = info.availableVersionCode;
      // Play는 업데이트가 없을 때 이 값이 임의라고 문서에 적어 두었고, 어느
      // 경우에도 null일 수 있다. 코드가 없으면 «나중에»를 기억할 대상이
      // 없으므로, 이름 붙일 수 없는 업데이트는 안내하지 않는다.
      if (versionCode == null) return null;
      return PendingUpdate(
        versionCode: versionCode,
        stalenessDays: info.clientVersionStalenessDays,
      );
    } on Object catch (error) {
      // 예외적인 경우가 아니라 평상시다. Play가 설치하지 않은 빌드 전부에서
      // — 디버그 실행, 사이드로드, Play 서비스 없는 에뮬레이터 — 그리고
      // 네트워크가 없는 기기에서 던진다. 사용자에게는 전부 같은 뜻이다.
      debugPrint('LOOPET: Play에 업데이트를 묻지 못했다: $error');
      return null;
    }
  }

  @override
  Future<bool> openStore() async {
    final String packageName;
    try {
      packageName = (await PackageInfo.fromPlatform()).packageName;
    } on Object catch (error) {
      debugPrint('LOOPET: 패키지 이름을 읽지 못했다: $error');
      return false;
    }
    if (packageName.isEmpty) return false;

    // Play 앱을 먼저 쓴다. 사용자가 실제로 «업데이트»를 누를 수 있는 곳에서
    // 목록이 열려야 한다. 웹 주소는 `market:` 스킴에 답할 Play 앱이 없는
    // 기기용 후퇴로, 브라우저로라도 같은 페이지에 닿는다.
    final targets = [
      Uri.parse('market://details?id=$packageName'),
      Uri.https('play.google.com', '/store/apps/details', {'id': packageName}),
    ];
    for (final target in targets) {
      try {
        if (await launchUrl(target, mode: LaunchMode.externalApplication)) {
          return true;
        }
      } on Object catch (error) {
        debugPrint('LOOPET: $target 를 열지 못했다: $error');
      }
    }
    return false;
  }
}
