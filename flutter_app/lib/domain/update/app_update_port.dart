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

/// 앱이 스토어에 바라는 것 — 플러그인은 이 뒤에 둔다.
///
/// 이 뒤에 있는 것은 전부 Android·Play 전용이고, 쓸 수 있는 때보다 쓸 수 없는
/// 때가 훨씬 많다. `InAppUpdate.checkForUpdate`는 Play가 설치하지 않은 빌드
/// 전부에서 예외를 던진다 — 모든 디버그 실행, 모든 사이드로드, 테스트 전체가
/// 거기 해당한다.
abstract interface class AppUpdatePort {
  /// 이 포트가 스토어에 물을 수 있는가.
  ///
  /// 설정에 «업데이트 확인» 행을 그릴지 정하는 데만 쓴다. 물어볼 스토어가 없는
  /// 빌드에서 그 행은 무엇을 눌러도 «최신 버전이에요»라고 답하는 죽은
  /// 컨트롤이 된다. [check]가 실패를 «없음»으로 접는 것과는 다른 이야기다 —
  /// 그쪽은 물어본 결과이고, 이쪽은 물어볼 상대가 있는지다.
  bool get canCheck;

  /// 스토어에서 기다리는 업데이트, 없으면 null.
  ///
  /// 물어보지도 못한 경우에도 null이다. 둘을 한 경우로 합친 것은 일부러다.
  /// Play에 닿지 못하는 앱은 어느 쪽이든 사용자에게 내놓을 것이 없고, 실패를
  /// 드러내면 Play 서비스가 없는 기기가 «실행할 때마다 불평하는 앱»이 된다.
  Future<PendingUpdate?> check();

  /// 사용자를 스토어 페이지로 넘긴다. 아무것도 열지 못하면 false.
  Future<bool> openStore();
}

/// 뒤에 스토어가 없는 빌드용 포트 — iOS, 웹, 테스트.
final class UnavailableUpdatePort implements AppUpdatePort {
  const UnavailableUpdatePort();

  @override
  bool get canCheck => false;

  @override
  Future<PendingUpdate?> check() async => null;

  @override
  Future<bool> openStore() async => false;
}
