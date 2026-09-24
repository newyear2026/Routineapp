import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/local/review_prompt_storage.dart';
import '../services/store_review_launcher.dart';

/// Google Play 인앱 리뷰 창을 **평생 한 번** 띄운다.
///
/// 규칙:
///
/// * 설치하고 **하루**가 지나야 한다. 첫날은 아직 앱을 평가할 만큼 써 보지
///   않았다.
/// * 홈에서 루틴을 **완료**한 직후에만 묻는다. 방금 해낸 순간이 앱에 가장
///   너그러운 때다. 앱을 열자마자 묻지 않는다 — 하려던 일을 가로막는다.
/// * 한 번 요청하면 다시 묻지 않는다. 창이 실제로 떴는지는 Play가 알려 주지
///   않으므로 «요청했음»을 기록한다. 놓친 사람은 설정의 «리뷰 남기기»가 받는다.
/// * «앱이 마음에 드세요?» 같은 사전 질문을 두지 않는다. 좋다고 답한 사람만
///   리뷰로 보내는 것은 Play 정책이 금지한다.
class ReviewPrompt {
  ReviewPrompt({
    bool? available,
    Future<DateTime?> Function()? installTimeLoader,
    Future<void> Function()? requester,
    Future<bool> Function()? requestedLoader,
    Future<void> Function(DateTime)? requestedSaver,
    DateTime Function()? now,
  })  : _available = available ?? storeReviewAvailable,
        _installTimeLoader = installTimeLoader ?? _loadInstallTime,
        _requester = requester ?? _requestPlayReview,
        _requestedLoader = requestedLoader ?? ReviewPromptStorage.hasRequested,
        _requestedSaver = requestedSaver ?? ReviewPromptStorage.markRequested,
        _now = now ?? DateTime.now;

  /// 설치 후 이만큼 지나야 묻는다.
  static const warmUp = Duration(days: 1);

  /// iOS는 아직 App Store에 없다 — 설정의 «리뷰 남기기»와 같은 판정을 쓴다.
  final bool _available;
  final Future<DateTime?> Function() _installTimeLoader;
  final Future<void> Function() _requester;
  final Future<bool> Function() _requestedLoader;
  final Future<void> Function(DateTime) _requestedSaver;
  final DateTime Function() _now;

  /// 연달아 완료를 누르면 첫 판정이 끝나기 전에 두 번째가 들어온다.
  bool _busy = false;
  bool _done = false;

  /// 홈에서 루틴 완료가 저장된 직후 부른다. 조건이 맞으면 리뷰 창을 띄운다.
  Future<void> onRoutineCompleted() async {
    if (!_available || _done || _busy) return;
    _busy = true;
    try {
      if (await _requestedLoader()) {
        _done = true;
        return;
      }
      final installedAt = await _installTimeLoader();
      if (installedAt == null) return;
      final now = _now();
      if (now.difference(installedAt) < warmUp) return;

      // 요청보다 기록을 먼저 한다. 창이 떠 있는 동안 앱이 죽어도 다음 실행에
      // 다시 묻지 않는다 — 한 번을 넘기는 쪽이 한 번을 놓치는 쪽보다 나쁘다.
      _done = true;
      await _requestedSaver(now);
      await _requester();
    } on Object catch (error) {
      debugPrint('LOOPET: 리뷰 요청을 건너뛴다: $error');
    } finally {
      _busy = false;
    }
  }
}

/// 설치 시각은 OS에 묻는다. 앱 업데이트로는 바뀌지 않는 첫 설치 시각이다.
/// 이 기능 이전 빌드부터 써 온 사람도 그대로 하루가 지난 것으로 센다.
Future<DateTime?> _loadInstallTime() async =>
    (await PackageInfo.fromPlatform()).installTime;

Future<void> _requestPlayReview() async {
  final review = InAppReview.instance;
  if (!await review.isAvailable()) return;
  await review.requestReview();
}
