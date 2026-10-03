/// 스토어에 올라와 기다리는 업데이트 — 그 뒤에 있는 빌드로 식별한다.
///
/// 버전 이름이 아니라 `versionCode`인 이유는 Play가 그것만 건네기 때문이다.
/// `AppUpdateInfo.availableVersionCode`는 스토어에 앉아 있는 빌드의 코드이고,
/// 이를 사용자가 알아볼 `1.2.0` 으로 바꿔 주는 API는 없다. 그래서 이 값은
/// 화면에 절대 내보내지 않는다. «나중에»를 기억할 신원일 뿐이다 — 이 업데이트를
/// 미뤄도 다음 업데이트는 다시 묻는다.
class PendingUpdate {
  const PendingUpdate({required this.versionCode, this.stalenessDays});

  final int versionCode;

  /// 이 기기의 Play가 업데이트를 처음 알게 된 뒤 지난 날수. Play가 말해 주지
  /// 않으면 null이다. 지금 정책은 쓰지 않는다. «이 빌드가 오래됐다» 규칙이
  /// 가질 수 있는 유일하게 정직한 입력이라 남겨 둔다 — 나중에 다시 물으면
  /// 왕복이 한 번 더 든다.
  final int? stalenessDays;

  @override
  bool operator ==(Object other) =>
      other is PendingUpdate &&
      other.versionCode == versionCode &&
      other.stalenessDays == stalenessDays;

  @override
  int get hashCode => Object.hash(versionCode, stalenessDays);

  @override
  String toString() =>
      'PendingUpdate(versionCode: $versionCode, stalenessDays: $stalenessDays)';
}

/// 조회 실패는 정상적으로 확인한 «업데이트 없음»과 구분한다.
class UpdateCheckResult {
  const UpdateCheckResult.success([this.pending]) : succeeded = true;
  const UpdateCheckResult.failed()
      : succeeded = false,
        pending = null;

  final bool succeeded;
  final PendingUpdate? pending;
}

/// 앱이 스토어에 바라는 것 — 플러그인은 이 뒤에 둔다.
abstract interface class AppUpdatePort {
  /// 이 포트가 스토어에 물을 수 있는가.
  ///
  /// 설정에 «업데이트 확인» 행을 그릴지 정하는 데만 쓴다. 물어볼 스토어가 없는
  /// 빌드에서는 행을 숨긴다.
  bool get canCheck;

  /// 성공한 결과의 pending이 null일 때만 최신 버전으로 판단한다.
  Future<UpdateCheckResult> check();

  /// 사용자를 스토어 페이지로 넘긴다. 아무것도 열지 못하면 false.
  Future<bool> openStore();
}

/// 뒤에 스토어가 없는 빌드용 포트 — iOS, 웹, 테스트.
final class UnavailableUpdatePort implements AppUpdatePort {
  const UnavailableUpdatePort();

  @override
  bool get canCheck => false;

  @override
  Future<UpdateCheckResult> check() async => const UpdateCheckResult.failed();

  @override
  Future<bool> openStore() async => false;
}
