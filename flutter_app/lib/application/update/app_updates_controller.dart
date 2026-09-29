import 'package:flutter/foundation.dart';

import '../../data/local/app_update_storage.dart';
import '../../domain/update/app_update_port.dart';
import '../../domain/utils/time_minutes.dart';
import '../services/app_version_service.dart';

/// LOOPET이 업데이트를 언제 꺼내고, 얼마나 고집스럽게 말하는가.
///
/// 규칙은 따로 보면 뜻이 안 통하므로 한자리에 모아 둔다:
///
/// * 스토어에는 **하루에 한 번**만 묻는다. 오프라인에서도 돌아가야 하는 앱이
///   찬 실행마다 왕복을 쓸 이유가 없다.
/// * 다이얼로그는 **업데이트당 한 번**만 끼어든다. «나중에하기»는 그 업데이트의
///   [PendingUpdate.versionCode] 에 기억되므로 같은 업데이트가 두 번 끼어들지
///   않고, 그 다음 업데이트는 다시 물을 기회를 얻는다.
/// * 미룬 업데이트는 배너로 남는다. 배너는 벽이 아니라 한 줄이다. 배너를 닫으면
///   이번 실행 동안만 사라지고 다음 실행에 돌아온다 — 이것이 이 기능이 허락받은
///   최대치다.
/// * 여기서 앱을 막을 수 있는 것은 없다. **강제 업데이트는 없다.** 구버전이
///   틀렸다고 말해 줄 서버가 애초에 없다.
class AppUpdates extends ChangeNotifier {
  AppUpdates({
    required AppUpdatePort port,
    Future<AppUpdateRecord> Function()? recordLoader,
    Future<void> Function(AppUpdateRecord)? recordSaver,
    DateTime Function()? now,
    AppVersionLoader versionLoader = loadAppVersion,
  })  : _port = port,
        _recordLoader = recordLoader ?? AppUpdateStorage.load,
        _recordSaver = recordSaver ?? AppUpdateStorage.save,
        _now = now ?? DateTime.now,
        _versionLoader = versionLoader;

  final AppUpdatePort _port;

  /// 루틴 저장소가 아니라 기기 장부를 읽고 쓴다 — 이유는
  /// [AppUpdateStorage] 문서에 적어 두었다.
  final Future<AppUpdateRecord> Function() _recordLoader;
  final Future<void> Function(AppUpdateRecord) _recordSaver;
  final DateTime Function() _now;

  /// 어떤 빌드가 돌고 있는지만 묻는다. 그것도 이미 설치된 안내를 버리기
  /// 위해서다 — [_restorePending] 참고.
  final AppVersionLoader _versionLoader;

  PendingUpdate? _pending;
  String? _checkedDay;
  int? _dismissedVersionCode;
  bool _promptShown = false;
  bool _promptVisible = false;
  bool _bannerHidden = false;
  bool _checking = false;
  int? _storedPendingCode;
  bool _loaded = false;
  bool _pendingRestored = false;

  PendingUpdate? get pending => _pending;

  /// 확인이 진행 중인가 — 설정 행이 «확인 중…»을 보여 주기 위해.
  bool get isChecking => _checking;

  /// 물어볼 스토어가 있는가 — 설정이 «업데이트 확인» 행을 그릴지 정한다.
  bool get canCheck => _port.canCheck;

  /// 지금 다이얼로그가 끼어들어야 하는가.
  bool get shouldPrompt =>
      _pending != null &&
      !_promptShown &&
      _pending!.versionCode != _dismissedVersionCode;

  /// 조용한 한 줄이 홈 맨 위에 있어야 하는가.
  ///
  /// 다이얼로그와 같은 때에는 절대 아니다. 그 판단에 [_promptShown] 만으로는
  /// 부족하다 — 이 값은 다이얼로그가 열리기 **전에** 서므로, 그 사이와 닫히기
  /// 전까지 배너가 스크림 뒤에 그려진다. 같은 소식이 두 벌, 그중 하나는 어둠
  /// 위로 읽히는 상태다. 그래서 다이얼로그가 떠 있는 동안만 참인 깃발을 따로
  /// 둔다.
  bool get showBanner =>
      _pending != null && !_bannerHidden && !shouldPrompt && !_promptVisible;

  /// 스토어에 묻는다 — 오늘 이미 물었다면 묻지 않는다.
  ///
  /// [force]는 설정의 «업데이트 확인» 행이다. 사용자가 직접 물었으므로 하루
  /// 예산이 적용되지 않고, 앞서 누른 «나중에»도 지운다 — 아직 나중이라고
  /// 생각한다면 그 행을 누르지 않았을 것이다.
  Future<PendingUpdate?> refresh({bool force = false}) async {
    if (_checking) return _pending;
    await _load();

    final today = TimeMinutes.dateYmd(_now());
    if (!force && _checkedDay == today) {
      await _restorePending();
      return _pending;
    }

    // 새로 물으러 가는 길에서는 되살리지 않는다. 곧 [_pending]을 덮어쓸 참이고,
    // 무엇보다 [_restorePending]이 세우는 [_promptShown] 때문에 방금 찾은
    // 업데이트가 끼어들 차례를 잃는다.
    _pendingRestored = true;
    _checking = true;
    if (force) notifyListeners();
    PendingUpdate? found;
    try {
      found = await _port.check();
    } finally {
      _checking = false;
    }

    _checkedDay = today;
    if (force) {
      _promptShown = false;
      _bannerHidden = false;
      _dismissedVersionCode = null;
    }
    _pending = found;
    await _persist();
    notifyListeners();
    return found;
  }

  /// 기기 장부를 읽는다. 여러 번 불러도 첫 번만 일한다.
  ///
  /// 안내를 되살리는 일([_restorePending])과 나눠 둔 이유는 그 둘이 필요한
  /// 때가 다르기 때문이다. 오늘 쓸 예산이 남았는지와 무엇을 미뤘는지는 늘
  /// 알아야 하지만, 저장해 둔 안내는 **다시 묻지 않는 날에만** 꺼내야 한다.
  Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;

    final record = await _recordLoader();
    _checkedDay = record.checkedDay;
    _dismissedVersionCode = record.dismissedVersionCode;
    _storedPendingCode = record.pendingVersionCode;
  }

  /// 오늘 이미 값을 치른 안내를 되살린다.
  ///
  /// [_pending] 은 이 상태에서 새 프로세스가 물려받지 못하는 유일한 조각이고,
  /// 하루 예산 때문에 그 프로세스는 다시 묻지도 않는다. 이것이 없으면 기능
  /// 전체가 찬 실행 딱 한 번만 살아 있다 — 그날의 두 번째 실행은 확인을
  /// 건너뛰고, 손에 아무것도 없으니 다이얼로그도 배너도 띄우지 않는다. 그래서
  /// 이 클래스가 «다음 실행에 돌아온다»고 약속한 배너가 날이 바뀌기 전까지
  /// 돌아올 수 없게 된다.
  ///
  /// 버전 코드만 남긴다. [PendingUpdate.stalenessDays] 는 한 순간에 던진
  /// 질문의 답이고, 어제 센 날수를 방금 센 것처럼 되돌려 놓는 것이 이 저장이
  /// 할 수 있는 유일하게 부정직한 일이다.
  Future<void> _restorePending() async {
    if (_pendingRestored) return;
    _pendingRestored = true;

    final code = _storedPendingCode;
    if (code == null) return;

    // 저장된 안내는 그것이 가리키는 업데이트보다 오래 산다. 설치하면 앱이
    // 같은 날 곧바로 돌아오는데, 예산은 이미 썼고 지금 돌고 있는 빌드의 코드가
    // 여전히 저장소에 앉아 있다. 그냥 두면 LOOPET은 배너가 그려진 바로 그
    // 버전을 광고한다.
    final installed = int.tryParse((await _versionLoader())?.buildNumber ?? '');
    if (installed != null && installed >= code) {
      await _persist();
      return;
    }

    _pending = PendingUpdate(versionCode: code);
    // 다이얼로그는 이미 자기 차례를 썼다 — 오늘 어느 실행이 그것을 열었다.
    // 재시작을 넘어 살아남는 것은 배너뿐이고, 배너는 이 정책의 조용한 절반이며
    // 스스로 돌아올 수 있는 유일한 절반이다.
    _promptShown = true;
    // [refresh]는 이 경로에서 곧바로 돌아간다. 알릴 사람이 없으므로 되살린
    // 배너를 여기서 알린다.
    notifyListeners();
  }

  Future<void> _persist() => _recordSaver((
        checkedDay: _checkedDay,
        dismissedVersionCode: _dismissedVersionCode,
        pendingVersionCode: _pending?.versionCode,
      ));

  /// 다이얼로그가 열린다 — 차례를 썼고, 화면에 있다.
  void markPromptShown() {
    if (_promptShown && _promptVisible) return;
    _promptShown = true;
    _promptVisible = true;
    notifyListeners();
  }

  /// 다이얼로그가 어떤 식으로든 닫혔다. 이제 배너가 이어받아도 된다.
  void markPromptClosed() {
    if (!_promptVisible) return;
    _promptVisible = false;
    notifyListeners();
  }

  /// «나중에하기» — 이 업데이트는 다시 끼어들지 않는다.
  Future<void> dismiss() async {
    _promptShown = true;
    _dismissedVersionCode = _pending?.versionCode;
    await _persist();
    notifyListeners();
  }

  /// 배너의 닫기 버튼. 이번 실행만인 것은 일부러다 — 클래스 문서 참고.
  void hideBanner() {
    if (_bannerHidden) return;
    _bannerHidden = true;
    notifyListeners();
  }

  Future<bool> openStore() => _port.openStore();
}
