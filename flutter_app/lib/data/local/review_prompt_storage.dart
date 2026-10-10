import 'package:shared_preferences/shared_preferences.dart';

/// 인앱 리뷰를 이미 요청했는지 — [ReviewPrompt]가 평생 한 번을 지키는 장부.
///
/// 업데이트 장부와 같이 사용자 데이터가 아니라 기기 장부라 `device.*` 키를 쓴다.
class ReviewPromptStorage {
  ReviewPromptStorage._();

  static const _kRequestedAt = 'device.review.requested_at_ms';

  static Future<bool> hasRequested() async {
    final p = await SharedPreferences.getInstance();
    return p.containsKey(_kRequestedAt);
  }

  static Future<void> markRequested(DateTime at) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kRequestedAt, at.millisecondsSinceEpoch);
  }
}
